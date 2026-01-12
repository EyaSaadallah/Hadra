import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final bool isActive;
  const NotificationsScreen({super.key, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final NotificationService notificationService = NotificationService();
    final String currentUserId = authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.getNotifications(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          if (isActive) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notificationService.markAllAsRead(currentUserId);
            });
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
  ) {
    String message = "";
    if (notification.type == 'follow') {
      message = "started following you.";
    } else if (notification.type == 'like') {
      message = "liked your post.";
    } else if (notification.type == 'comment') {
      message = "commented on your post.";
    } else if (notification.type == 'like_comment') {
      message = "liked your comment.";
    }

    final NotificationService notificationService = NotificationService();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Delete Notification"),
              content: const Text(
                "Are you sure you want to delete this notification?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Delete"),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Notification deleted")));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red[400],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            Text(
              "Delete",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(uid: notification.fromUid),
              ),
            );
          },
          child: CircleAvatar(
            backgroundImage:
                (notification.fromProfilePic != null &&
                    notification.fromProfilePic!.isNotEmpty)
                ? NetworkImage(notification.fromProfilePic!)
                : null,
            child:
                (notification.fromProfilePic == null ||
                    notification.fromProfilePic!.isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 14),
            children: [
              TextSpan(
                text: "${notification.fromName ?? 'Someone'} ",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: message),
            ],
          ),
        ),
        subtitle: Text(
          DateFormat.yMMMd().add_jm().format(notification.timestamp),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: notification.postImage != null
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(notification.postImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : notification.type == 'follow'
            ? OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(uid: notification.fromUid),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 30),
                ),
                child: const Text("View", style: TextStyle(fontSize: 12)),
              )
            : null,
        onTap: () {
          // Handle post navigation if needed
        },
      ),
    );
  }
}
