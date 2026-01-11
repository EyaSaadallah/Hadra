import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a notification
  Future<void> addNotification({
    required String toUid,
    required String fromUid,
    required String type,
    String? postId,
    String? postImage,
  }) async {
    try {
      // Don't notify if the user is interacting with their own content
      if (toUid == fromUid) return;

      // Get sender details
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(fromUid)
          .get();

      String? fromName;
      String? fromProfilePic;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        fromName = userData['username'] ?? userData['name'];
        fromProfilePic = userData['profilePic'];
      }

      var docRef = _firestore.collection('notifications').doc();

      NotificationModel notification = NotificationModel(
        id: docRef.id,
        toUid: toUid,
        fromUid: fromUid,
        type: type,
        postId: postId,
        postImage: postImage,
        timestamp: DateTime.now(),
        fromName: fromName,
        fromProfilePic: fromProfilePic,
      );

      await docRef.set(notification.toMap());
    } catch (e) {
      print("Error adding notification: $e");
    }
  }

  // Get notifications for a specific user
  Stream<List<NotificationModel>> getNotifications(String uid) {
    return _firestore
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .toList();

          // Sort in memory by timestamp descending
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return notifications;
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }
}
