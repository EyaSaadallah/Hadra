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

  // Send Message (with encryption)
  Future<void> sendMessage(
    String receiverId,
    String senderId,
    String message,
  ) async {
    final Timestamp timestamp = Timestamp.now();

    // Get chat room ID
    String chatRoomId = getChatRoomId(senderId, receiverId);

    // Encrypt the message before sending
    String encryptedMessage = EncryptionService.encryptMessage(
      message,
      chatRoomId,
    );

    MessageModel newMessage = MessageModel(
      senderId: senderId,
      receiverId: receiverId,
      message: encryptedMessage, // Store encrypted message
      timestamp: timestamp,
    );

    // Initialise or update the chat room document with participants and last message info
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'participants': [senderId, receiverId],
      'lastMessage': encryptedMessage,
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
        .orderBy('timestamp', descending: false)
        .snapshots();
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
