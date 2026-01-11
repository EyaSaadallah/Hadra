import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hadra/models/post_model.dart';
import 'package:hadra/models/user_model.dart';
import 'package:hadra/services/auth_service.dart';
import 'package:hadra/services/post_service.dart';
import 'package:hadra/screens/comments_screen.dart';
import 'package:hadra/screens/profile_screen.dart';

class PostWidget extends StatefulWidget {
  final PostModel post;
  PostWidget({super.key, required this.post});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _showHeartOverlay = false;

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _authService.currentUser?.uid ?? '';
    final bool isLiked = widget.post.likes.contains(currentUserId);

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(widget.post.ownerUid)
          .snapshots(),
      builder: (context, userSnapshot) {
        UserModel? owner;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          owner = UserModel.fromMap(
            userSnapshot.data!.data() as Map<String, dynamic>,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            ListTile(
              leading: GestureDetector(
                onTap: () {
                  if (owner != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(uid: owner!.uid),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      (owner?.profilePic != null &&
                          owner!.profilePic!.isNotEmpty)
                      ? NetworkImage(owner.profilePic!)
                      : null,
                  child:
                      (owner?.profilePic == null || owner!.profilePic!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
              title: GestureDetector(
                onTap: () {
                  if (owner != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(uid: owner!.uid),
                      ),
                    );
                  }
                },
                child: Text(
                  owner?.username ?? owner?.name ?? "User",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              trailing: const Icon(Icons.more_vert),
            ),
            // Post Image with Double Tap to Like
            GestureDetector(
              onDoubleTap: () async {
                if (!isLiked) {
                  await PostService().toggleLike(
                    widget.post.id,
                    currentUserId,
                    false,
                  );
                }
                setState(() {
                  _showHeartOverlay = true;
                });
                Future.delayed(const Duration(milliseconds: 700), () {
                  if (mounted) {
                    setState(() {
                      _showHeartOverlay = false;
                    });
                  }
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    widget.post.imageUrl,
                    width: double.infinity,
                    height: 400,
                    fit: BoxFit.cover,
                  ),
                  if (_showHeartOverlay)
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 100,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Post Actions
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.black,
                  ),
                  onPressed: () {
                    PostService().toggleLike(
                      widget.post.id,
                      currentUserId,
                      isLiked,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CommentsScreen(postId: widget.post.id),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  onPressed: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                ),
              ],
            ),
            // Likes count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "${widget.post.likes.length} likes",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Comments count link
            if (widget.post.commentCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 2,
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CommentsScreen(postId: widget.post.id),
                      ),
                    );
                  },
                  child: Text(
                    "View all ${widget.post.commentCount} comments",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
            // Caption
            if (widget.post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4,
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: "${owner?.username ?? owner?.name ?? 'User'} ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: widget.post.caption),
                    ],
                  ),
                ),
              ),
            // Timestamp
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4,
              ),
              child: Text(
                DateFormat.yMMMd().format(widget.post.timestamp),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}
