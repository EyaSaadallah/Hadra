import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String? id;
  final String senderId;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final bool isLiked;
  final bool isSeen;
  final String type; // 'text', 'image', 'video', 'document', 'audio'
  final String? mediaUrl;

  MessageModel({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isLiked = false,
    this.isSeen = false,
    this.type = 'text',
    this.mediaUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isLiked': isLiked,
      'isSeen': isSeen,
      'type': type,
      'mediaUrl': mediaUrl,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isLiked: map['isLiked'] ?? false,
      isSeen: map['isSeen'] ?? false,
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
    );
  }
}
