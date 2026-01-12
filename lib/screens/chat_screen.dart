import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/encryption_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/imagekit_service.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/audio_player_widget.dart';

class ChatScreen extends StatefulWidget {
  final UserModel receiverUser;
  const ChatScreen({super.key, required this.receiverUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ImageKitService _imageKitService = ImageKitService();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  final ValueNotifier<bool> _hasText = ValueNotifier<bool>(false);

  void _sendMedia(String type, File file) async {
    String senderId = _authService.currentUser!.uid;
    String fileName = "${type}_${DateTime.now().millisecondsSinceEpoch}";

    // Show a snackbar or loading indicator
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Sending $type...")));

    String? mediaUrl = await _imageKitService.uploadImage(
      file,
      fileName,
      folder: 'hadra/chats',
    );

    if (!mounted) return;

    if (mediaUrl != null) {
      await _chatService.sendMessage(
        widget.receiverUser.uid,
        senderId,
        "", // Message can be empty for media
        type: type,
        mediaUrl: mediaUrl,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload failed")));
    }
  }

  void _pickMedia(String type) async {
    try {
      if (type == 'image' || type == 'camera') {
        final XFile? image = await _picker.pickImage(
          source: type == 'image' ? ImageSource.gallery : ImageSource.camera,
        );
        if (!mounted) return;
        if (image != null) {
          _sendMedia('image', File(image.path));
        }
      } else if (type == 'video') {
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.gallery,
        );
        if (!mounted) return;
        if (video != null) {
          _sendMedia('video', File(video.path));
        }
      } else if (type == 'document' || type == 'audio') {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: type == 'document' ? FileType.any : FileType.audio,
          allowMultiple: false,
        );
        if (!mounted) return;
        if (result != null && result.files.single.path != null) {
          _sendMedia(type, File(result.files.single.path!));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error picking $type: $e")));
      }
    }
  }

  Future<void> _openMedia(String? url) async {
    if (url == null || url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open the file")),
        );
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String senderId = _authService.currentUser!.uid;
      await _chatService.sendMessage(
        widget.receiverUser.uid,
        senderId,
        _messageController.text,
      );
      _messageController.clear();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String filePath =
            '${appDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordingPath = filePath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Recording error: $e")));
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (_recordingPath != null) {
        _sendMedia('audio', File(_recordingPath!));
        _recordingPath = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Stop recording error: $e")));
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();
      if (_recordingPath != null && File(_recordingPath!).existsSync()) {
        await File(_recordingPath!).delete();
      }
      setState(() {
        _isRecording = false;
        _recordingPath = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Cancel recording error: $e")));
      }
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _messageController.dispose();
    _hasText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = _authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfileScreen(uid: widget.receiverUser.uid),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    (widget.receiverUser.profilePic != null &&
                        widget.receiverUser.profilePic!.isNotEmpty)
                    ? NetworkImage(widget.receiverUser.profilePic!)
                    : null,
                child:
                    (widget.receiverUser.profilePic == null ||
                        widget.receiverUser.profilePic!.isEmpty)
                    ? Text(widget.receiverUser.name?[0].toUpperCase() ?? '?')
                    : null,
              ),
              const SizedBox(width: 12),
              Text(widget.receiverUser.name ?? 'Chat'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(
                currentUserId,
                widget.receiverUser.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final messages = snapshot.data!.docs;

                // Mark messages as seen
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _chatService.markMessagesAsSeen(
                    currentUserId,
                    widget.receiverUser.uid,
                  );
                });

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    MessageModel msg = MessageModel.fromMap(data, id: doc.id);
                    bool isMe = msg.senderId == currentUserId;

                    // Decrypt the message
                    String chatRoomId = _chatService.getChatRoomId(
                      currentUserId,
                      widget.receiverUser.uid,
                    );
                    String decryptedMessage = EncryptionService.decryptMessage(
                      msg.message,
                      chatRoomId,
                    );

                    return GestureDetector(
                      onDoubleTap: () {
                        HapticFeedback.heavyImpact();
                        _chatService.toggleLikeMessage(
                          currentUserId,
                          widget.receiverUser.uid,
                          msg.id!,
                          msg.isLiked,
                        );
                      },
                      onLongPress: () {
                        HapticFeedback.selectionClick();
                        _showReactionMenu(context, msg, currentUserId);
                      },
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.bottomLeft,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blue[100]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  _buildMessageContent(msg, decryptedMessage),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'HH:mm',
                                        ).format(msg.timestamp.toDate()),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          msg.isSeen
                                              ? Icons.done_all
                                              : Icons.done,
                                          size: 14,
                                          color: msg.isSeen
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (msg.isLiked)
                              Positioned(
                                bottom: -2,
                                right: isMe ? 0 : null,
                                left: isMe ? null : 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  void _showReactionMenu(
    BuildContext context,
    MessageModel msg,
    String currentUserId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 100,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _reactionIcon(Icons.favorite, Colors.red, msg, currentUserId),
            _reactionIcon(Icons.thumb_up, Colors.blue, msg, currentUserId),
            _reactionIcon(
              Icons.sentiment_very_satisfied,
              Colors.amber,
              msg,
              currentUserId,
            ),
            _reactionIcon(
              Icons.sentiment_very_dissatisfied,
              Colors.amber,
              msg,
              currentUserId,
            ),
            _reactionIcon(Icons.star, Colors.orange, msg, currentUserId),
          ],
        ),
      ),
    );
  }

  Widget _reactionIcon(
    IconData icon,
    Color color,
    MessageModel msg,
    String currentUserId,
  ) {
    return IconButton(
      icon: Icon(icon, color: color, size: 30),
      onPressed: () {
        Navigator.pop(context);
        // For now, any reaction toggles the 'isLiked' heart for simplicity,
        // as requested specifically for the 'like' functionality.
        _chatService.toggleLikeMessage(
          currentUserId,
          widget.receiverUser.uid,
          msg.id!,
          msg.isLiked,
        );
      },
    );
  }

  Widget _buildMessageContent(MessageModel msg, String decryptedText) {
    if (msg.type == 'image') {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black.withOpacity(0.9),
                    ),
                  ),
                  Center(
                    child: Hero(
                      tag: msg.mediaUrl!,
                      child: Image.network(msg.mediaUrl!, fit: BoxFit.contain),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Hero(
          tag: msg.mediaUrl!,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              msg.mediaUrl!,
              width: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Text("Image load failed"),
            ),
          ),
        ),
      );
    } else if (msg.type == 'video') {
      return GestureDetector(
        onTap: () => _openMedia(msg.mediaUrl),
        child: Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
          ),
        ),
      );
    } else if (msg.type == 'document') {
      return GestureDetector(
        onTap: () => _openMedia(msg.mediaUrl),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text("Document", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    } else if (msg.type == 'audio') {
      return AudioPlayerWidget(audioUrl: msg.mediaUrl!);
    } else {
      return Text(decryptedText, style: const TextStyle(fontSize: 16));
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _attachmentItem(
                icon: Icons.description,
                color: Colors.deepPurple,
                label: "Document",
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia('document');
                },
              ),
              _attachmentItem(
                icon: Icons.photo_library,
                color: Colors.blue,
                label: "Photos & Videos",
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(
                    'image',
                  ); // Simplified for choosing images/videos logic
                },
              ),
              _attachmentItem(
                icon: Icons.camera_alt,
                color: Colors.pink,
                label: "Camera",
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia('camera');
                },
              ),
              _attachmentItem(
                icon: Icons.headset,
                color: Colors.orange,
                label: "Audio",
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia('audio');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _attachmentItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: _isRecording
          ? Row(
              children: [
                const Icon(Icons.mic, color: Colors.red),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Recording...",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            )
          : Row(
              children: [
                IconButton(
                  onPressed: _showAttachmentMenu,
                  icon: const Icon(Icons.add, color: Colors.blue),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (value) {
                      _hasText.value = value.trim().isNotEmpty;
                    },
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: _hasText,
                  builder: (context, hasText, child) {
                    return IconButton(
                      onPressed: hasText ? _sendMessage : _startRecording,
                      icon: Icon(
                        hasText ? Icons.send : Icons.mic,
                        color: Colors.blue,
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
