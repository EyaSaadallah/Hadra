import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String postId;
  final String uid;
  final String text;
  final DateTime timestamp;
  final List<String> likes;

  CommentModel({
    required this.id,
    required this.postId,
    required this.uid,
    required this.text,
    required this.timestamp,
    required this.likes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'uid': uid,
      'text': text,
      'timestamp': timestamp,
      'likes': likes,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    var rawTimestamp = map['timestamp'];
    if (rawTimestamp is Timestamp) {
      parsedDate = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedDate = DateTime.parse(rawTimestamp);
    } else {
      parsedDate = DateTime.now();
    }

    return CommentModel(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      uid: map['uid'] ?? '',
      text: map['text'] ?? '',
      timestamp: parsedDate,
      likes: List<String>.from(map['likes'] ?? []),
    );
  }
}
