import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hadra/models/comment_model.dart';
import 'package:hadra/models/user_model.dart';
import 'package:hadra/services/auth_service.dart';
import 'package:hadra/services/post_service.dart';
import 'package:intl/intl.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _postComment() async {
    final user = _authService.currentUser;
    if (user != null && _commentController.text.isNotEmpty) {
      await _postService.addComment(
        widget.postId,
        user.uid,
        _commentController.text.trim(),
      );
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Comments",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _postService.getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No comments yet."));
                }

                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('users')
                          .doc(comment.uid)
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        UserModel? sender;
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          sender = UserModel.fromMap(
                            userSnapshot.data!.data() as Map<String, dynamic>,
                          );
                        }

                        final isLiked = comment.likes.contains(
                          _authService.currentUser?.uid ?? '',
                        );

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                (sender?.profilePic != null &&
                                    sender!.profilePic!.isNotEmpty)
                                ? NetworkImage(sender.profilePic!)
                                : null,
                            child:
                                (sender?.profilePic == null ||
                                    sender!.profilePic!.isEmpty)
                                ? const Icon(Icons.person, size: 20)
                                : null,
                          ),
                          title: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black),
                              children: [
                                TextSpan(
                                  text:
                                      "${sender?.username ?? sender?.name ?? 'User'} ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: comment.text),
                              ],
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat.yMMMd().add_jm().format(
                                  comment.timestamp,
                                ),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              if (comment.likes.isNotEmpty)
                                Text(
                                  "${comment.likes.length} like${comment.likes.length > 1 ? 's' : ''}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                              size: 16,
                            ),
                            onPressed: () {
                              _postService.toggleCommentLike(
                                widget.postId,
                                comment.id,
                                _authService.currentUser?.uid ?? '',
                                isLiked,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                StreamBuilder<UserModel?>(
                  stream: _authService.currentUserStream,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          (user?.profilePic != null &&
                              user!.profilePic!.isNotEmpty)
                          ? NetworkImage(user.profilePic!)
                          : null,
                      child:
                          (user?.profilePic == null ||
                              user!.profilePic!.isEmpty)
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Add a comment...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _postComment,
                  child: const Text(
                    "Post",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
