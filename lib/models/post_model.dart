import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String ownerUid;
  final String imageUrl;
  final String caption;
  final DateTime timestamp;
  final List<String> likes;
  final int commentCount;

  PostModel({
    required this.id,
    required this.ownerUid,
    required this.imageUrl,
    required this.caption,
    required this.timestamp,
    required this.likes,
    required this.commentCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'imageUrl': imageUrl,
      'caption': caption,
      'timestamp':
          timestamp, // Firestore handles DateTime directly as Timestamp
      'likes': likes,
      'commentCount': commentCount,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    var rawTimestamp = map['timestamp'];
    if (rawTimestamp is Timestamp) {
      parsedDate = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedDate = DateTime.parse(rawTimestamp);
    } else {
      parsedDate = DateTime.now();
    }

    return PostModel(
      id: map['id'] ?? '',
      ownerUid: map['ownerUid'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      timestamp: parsedDate,
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0,
    );
  }
}
