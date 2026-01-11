import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String toUid;
  final String fromUid;
  final String type; // 'follow', 'like', 'comment'
  final String? postId;
  final String? postImage;
  final DateTime timestamp;
  final bool isRead;
  final String? fromName;
  final String? fromProfilePic;

  NotificationModel({
    required this.id,
    required this.toUid,
    required this.fromUid,
    required this.type,
    this.postId,
    this.postImage,
    required this.timestamp,
    this.isRead = false,
    this.fromName,
    this.fromProfilePic,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'toUid': toUid,
      'fromUid': fromUid,
      'type': type,
      'postId': postId,
      'postImage': postImage,
      'timestamp': timestamp,
      'isRead': isRead,
      'fromName': fromName,
      'fromProfilePic': fromProfilePic,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      toUid: map['toUid'] ?? '',
      fromUid: map['fromUid'] ?? '',
      type: map['type'] ?? '',
      postId: map['postId'],
      postImage: map['postImage'],
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      fromName: map['fromName'],
      fromProfilePic: map['fromProfilePic'],
    );
  }
}
