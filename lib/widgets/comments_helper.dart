import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../screens/profile_screen.dart';
import 'likes_helper.dart';

class CommentsHelper {
  static void showComments(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CommentsBottomSheet(postId: postId);
      },
    );
  }
}

class _CommentsBottomSheet extends StatefulWidget {
  final String postId;
  const _CommentsBottomSheet({required this.postId});

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
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
      // FocusScope.of(context).unfocus(); // Optional: close keyboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  "Comments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),

              // Comments List
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
                      controller: scrollController,
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
                            if (userSnapshot.hasData &&
                                userSnapshot.data!.exists) {
                              sender = UserModel.fromMap(
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>,
                              );
                            }

                            final isLiked = comment.likes.contains(
                              _authService.currentUser?.uid ?? '',
                            );

                            return ListTile(
                              leading: GestureDetector(
                                onTap: () {
                                  if (sender != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProfileScreen(uid: sender!.uid),
                                      ),
                                    );
                                  }
                                },
                                child: CircleAvatar(
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
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          if (sender != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfileScreen(
                                                      uid: sender!.uid,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
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
                                    GestureDetector(
                                      onTap: () => LikesHelper.showLikes(
                                        context,
                                        comment.likes,
                                      ),
                                      child: Text(
                                        "${comment.likes.length} like${comment.likes.length > 1 ? 's' : ''}",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
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

              // Comment Input Field
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8.0,
                  top: 8.0,
                ),
                child: Row(
                  children: [
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
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
