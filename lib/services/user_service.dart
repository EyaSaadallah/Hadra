import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Follow a user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);
      final followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      await _firestore.runTransaction((transaction) async {
        final followingDoc = await transaction.get(followingRef);

        if (!followingDoc.exists) {
          transaction.set(followingRef, {
            'timestamp': FieldValue.serverTimestamp(),
          });
          transaction.set(followerRef, {
            'timestamp': FieldValue.serverTimestamp(),
          });
          transaction.update(currentUserRef, {
            'followingCount': FieldValue.increment(1),
          });
          transaction.update(targetUserRef, {
            'followersCount': FieldValue.increment(1),
          });
        }
      });

      // Send notification (outside transaction is fine)
      await _notificationService.addNotification(
        toUid: targetUserId,
        fromUid: currentUserId,
        type: 'follow',
      );
    } catch (e) {
      print("Error following user: $e");
      rethrow;
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);
      final followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      await _firestore.runTransaction((transaction) async {
        final followingDoc = await transaction.get(followingRef);

        if (followingDoc.exists) {
          transaction.delete(followingRef);
          transaction.delete(followerRef);
          transaction.update(currentUserRef, {
            'followingCount': FieldValue.increment(-1),
          });
          transaction.update(targetUserRef, {
            'followersCount': FieldValue.increment(-1),
          });
        }
      });
    } catch (e) {
      print("Error unfollowing user: $e");
      rethrow;
    }
  }

  // Check if current user is following target user
  Stream<bool> isFollowing(String currentUserId, String targetUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Get user data by UID (Future version)
  Future<UserModel?> getUserDataFuture(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists
        ? UserModel.fromMap(doc.data() as Map<String, dynamic>)
        : null;
  }

  // Get user data by UID
  Stream<UserModel?> getUserData(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? UserModel.fromMap(doc.data() as Map<String, dynamic>)
              : null,
        );
  }

  // Get followers of a user
  Stream<List<UserModel>> getFollowers(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .asyncMap((snapshot) async {
          List<UserModel> followers = [];
          for (var doc in snapshot.docs) {
            var userDoc = await _firestore
                .collection('users')
                .doc(doc.id)
                .get();
            if (userDoc.exists) {
              followers.add(
                UserModel.fromMap(userDoc.data() as Map<String, dynamic>),
              );
            }
          }
          return followers;
        });
  }

  // Get following of a user
  Stream<List<UserModel>> getFollowing(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .asyncMap((snapshot) async {
          List<UserModel> following = [];
          for (var doc in snapshot.docs) {
            var userDoc = await _firestore
                .collection('users')
                .doc(doc.id)
                .get();
            if (userDoc.exists) {
              following.add(
                UserModel.fromMap(userDoc.data() as Map<String, dynamic>),
              );
            }
          }
          return following;
        });
  }

  // Get multiple users by their IDs
  Stream<List<UserModel>> getUsersFromUids(List<String> uids) {
    if (uids.isEmpty) return Stream.value([]);

    // Firestore whereIn has a limit of 30, for now we assume likes are fewer or we handle it simply
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: uids)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Get actual followers count (real-time)
  Stream<int> getFollowerCount(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get actual following count (real-time)
  Stream<int> getFollowingCount(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
