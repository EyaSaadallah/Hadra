import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hadra/models/post_model.dart';
import 'package:hadra/models/comment_model.dart';
import 'package:hadra/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Create Post
  Future<void> createPost(PostModel post) async {
    try {
      await _firestore.collection('posts').doc(post.id).set(post.toMap());
      // Increment user's posts count
      await _firestore.collection('users').doc(post.ownerUid).update({
        'postsCount': FieldValue.increment(1),
      });
    } catch (e) {
      print("Error creating post: $e");
      rethrow;
    }
  }

  // Add Comment
  Future<void> addComment(String postId, String userId, String text) async {
    try {
      final String commentId = const Uuid().v4();
      final comment = CommentModel(
        id: commentId,
        postId: postId,
        uid: userId,
        text: text,
        timestamp: DateTime.now(),
        likes: [],
      );

      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .set(comment.toMap());

      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Send notification to post owner
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        final postData = postDoc.data() as Map<String, dynamic>;
        await _notificationService.addNotification(
          toUid: postData['ownerUid'],
          fromUid: userId,
          type: 'comment',
          postId: postId,
          postImage: postData['imageUrl'],
        );
      }
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  // Like Comment
  Future<void> toggleCommentLike(
    String postId,
    String commentId,
    String userId,
    bool isLiked,
  ) async {
    try {
      if (isLiked) {
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .update({
              'likes': FieldValue.arrayRemove([userId]),
            });
      } else {
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .update({
              'likes': FieldValue.arrayUnion([userId]),
            });
      }
    } catch (e) {
      print("Error toggling comment like: $e");
    }
  }

  // Get Comments
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get Posts (Feed) - Simplified for now
  Stream<List<PostModel>> getFeedPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get User Posts
  Stream<List<PostModel>> getUserPosts(String uid) {
    return _firestore
        .collection('posts')
        .where('ownerUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
              .map((doc) => PostModel.fromMap(doc.data()))
              .toList();

          // Sort in memory by timestamp descending
          posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return posts;
        });
  }

  // Like Post
  Future<void> toggleLike(String postId, String userId, bool isLiked) async {
    try {
      if (isLiked) {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([userId]),
        });

        // Send notification to post owner (only if liking)
        final postDoc = await _firestore.collection('posts').doc(postId).get();
        if (postDoc.exists) {
          final postData = postDoc.data() as Map<String, dynamic>;
          await _notificationService.addNotification(
            toUid: postData['ownerUid'],
            fromUid: userId,
            type: 'like',
            postId: postId,
            postImage: postData['imageUrl'],
          );
        }
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }
}
