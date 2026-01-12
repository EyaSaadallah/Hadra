import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'encryption_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to get chat room ID
  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join("_");
  }

  // Send Message (with encryption support for text)
  Future<void> sendMessage(
    String receiverId,
    String senderId,
    String message, {
    String type = 'text',
    String? mediaUrl,
  }) async {
    final Timestamp timestamp = Timestamp.now();

    // Get chat room ID
    String chatRoomId = getChatRoomId(senderId, receiverId);

    // Encrypt the message if it's text
    String storedMessage = message;
    if (type == 'text' && message.isNotEmpty) {
      storedMessage = EncryptionService.encryptMessage(message, chatRoomId);
    }

    MessageModel newMessage = MessageModel(
      senderId: senderId,
      receiverId: receiverId,
      message: storedMessage,
      timestamp: timestamp,
      type: type,
      mediaUrl: mediaUrl,
    );

    // Initialise or update the chat room document with participants and last message info
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'participants': [senderId, receiverId],
      'lastMessage': type == 'text' ? storedMessage : 'Media: $type',
      'lastMessageTimestamp': timestamp,
    }, SetOptions(merge: true));

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  // Get Messages
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    String chatRoomId = getChatRoomId(userId, otherUserId);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Toggle Like Message
  Future<void> toggleLikeMessage(
    String userId,
    String otherUserId,
    String messageId,
    bool currentIsLiked,
  ) async {
    String chatRoomId = getChatRoomId(userId, otherUserId);
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'isLiked': !currentIsLiked});
  }

  // Mark Messages as Seen
  Future<void> markMessagesAsSeen(String userId, String otherUserId) async {
    String chatRoomId = getChatRoomId(userId, otherUserId);
    var snapshot = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isSeen', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isSeen': true});
    }
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount(String userId, String otherUserId) {
    String chatRoomId = getChatRoomId(userId, otherUserId);
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isSeen', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get total unread count across all rooms
  Stream<int> getTotalUnreadCount(String currentUserId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          int total = 0;
          for (var doc in snapshot.docs) {
            var messagesSnapshot = await _firestore
                .collection('chat_rooms')
                .doc(doc.id)
                .collection('messages')
                .where('receiverId', isEqualTo: currentUserId)
                .where('isSeen', isEqualTo: false)
                .get();
            total += messagesSnapshot.docs.length;
          }
          return total;
        });
  }

  // Get active chat users
  Stream<List<UserModel>> getChatUsers(String currentUserId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> userWithTimestamp = [];
          for (var doc in snapshot.docs) {
            List<dynamic> participants = doc['participants'];
            String otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
            );
            Timestamp? timestamp = doc['lastMessageTimestamp'] as Timestamp?;

            var userDoc = await _firestore
                .collection('users')
                .doc(otherUserId)
                .get();
            if (userDoc.exists) {
              userWithTimestamp.add({
                'user': UserModel.fromMap(
                  userDoc.data() as Map<String, dynamic>,
                ),
                'timestamp': timestamp ?? Timestamp(0, 0),
              });
            }
          }

          // Sort in memory by timestamp descending
          userWithTimestamp.sort(
            (a, b) => (b['timestamp'] as Timestamp).compareTo(
              a['timestamp'] as Timestamp,
            ),
          );

          return userWithTimestamp.map((e) => e['user'] as UserModel).toList();
        });
  }

  // Get All Users (except current)
  Stream<List<UserModel>> getUsers(String currentUserId) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    });
  }
}
