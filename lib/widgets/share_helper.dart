import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/post_model.dart';

class ShareHelper {
  static void showShareSheet(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ShareBottomSheet(post: post);
      },
    );
  }
}

class _ShareBottomSheet extends StatefulWidget {
  final PostModel post;
  const _ShareBottomSheet({required this.post});

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _authService.currentUser?.uid ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
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
                  "Share",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: "Search following...",
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Following List
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: _userService.getFollowing(currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("You are not following anyone yet."),
                      );
                    }

                    var users = snapshot.data!;
                    if (_searchQuery.isNotEmpty) {
                      users = users
                          .where(
                            (u) =>
                                (u.username?.toLowerCase().contains(
                                      _searchQuery,
                                    ) ??
                                    false) ||
                                (u.name?.toLowerCase().contains(_searchQuery) ??
                                    false),
                          )
                          .toList();
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                (user.profilePic != null &&
                                    user.profilePic!.isNotEmpty)
                                ? NetworkImage(user.profilePic!)
                                : null,
                            child:
                                (user.profilePic == null ||
                                    user.profilePic!.isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(user.username ?? user.name ?? 'User'),
                          subtitle: Text(user.name ?? ''),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              try {
                                // Send the post as a message
                                await _chatService.sendMessage(
                                  user.uid,
                                  currentUserId,
                                  "Shared a post: ${widget.post.caption}",
                                  type:
                                      'text', // Using text type but with postId
                                  mediaUrl: widget.post.imageUrl,
                                  postId: widget.post.id,
                                );

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Shared with ${user.username ?? user.name}",
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Failed to share: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Send"),
                          ),
                        );
                      },
                    );
                  },
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
    _searchController.dispose();
    super.dispose();
  }
}
