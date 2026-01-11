import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Follow a user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      // 1. Add targetUserId to current user's following subcollection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .set({'timestamp': FieldValue.serverTimestamp()});

      // 2. Add currentUserId to target user's followers subcollection
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId)
          .set({'timestamp': FieldValue.serverTimestamp()});

      // 3. Increment current user's followingCount
      await _firestore.collection('users').doc(currentUserId).update({
        'followingCount': FieldValue.increment(1),
      });

      // 4. Increment target user's followersCount
      await _firestore.collection('users').doc(targetUserId).update({
        'followersCount': FieldValue.increment(1),
      });

      // 5. Send notification
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
      // 1. Remove targetUserId from current user's following subcollection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .delete();

      // 2. Remove currentUserId from target user's followers subcollection
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId)
          .delete();

      // 3. Decrement current user's followingCount
      await _firestore.collection('users').doc(currentUserId).update({
        'followingCount': FieldValue.increment(-1),
      });

      // 4. Decrement target user's followersCount
      await _firestore.collection('users').doc(targetUserId).update({
        'followersCount': FieldValue.increment(-1),
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
}
