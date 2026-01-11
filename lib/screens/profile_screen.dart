import 'package:flutter/material.dart';
import 'package:hadra/models/user_model.dart';
import 'package:hadra/models/post_model.dart';
import 'package:hadra/services/auth_service.dart';
import 'package:hadra/services/post_service.dart';
import 'package:hadra/screens/edit_profile_screen.dart';
import 'package:hadra/screens/post_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String uid;
  ProfileScreen({super.key, required this.uid});

  final AuthService _authService = AuthService();
  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    bool isMe = _authService.currentUser?.uid == uid;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<UserModel?>(
          stream: isMe
              ? _authService.currentUserStream
              : null, // Fallback for other users later
          builder: (context, snapshot) {
            return Text(
              snapshot.data?.username ?? snapshot.data?.name ?? "Profile",
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),
        actions: [
          if (isMe)
            IconButton(
              onPressed: () => _authService.signOut(),
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: isMe
            ? _authService.currentUserStream
            : null, // Update for other users later
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final user = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Info Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            (user.profilePic != null &&
                                user.profilePic!.isNotEmpty)
                            ? NetworkImage(user.profilePic!)
                            : null,
                        child:
                            (user.profilePic == null ||
                                user.profilePic!.isEmpty)
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn("Posts", user.postsCount),
                            _buildStatColumn("Followers", user.followersCount),
                            _buildStatColumn("Following", user.followingCount),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Name and Bio
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? "No Name",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(user.bio!),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Edit Profile Button
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Edit Profile",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                // Posts Grid
                const Divider(),
                StreamBuilder<List<PostModel>>(
                  stream: _postService.getUserPosts(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Error loading posts: ${snapshot.error}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Tip: Check your debug console for a link to create an index in Firestore.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final posts = snapshot.data!;

                    if (posts.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.grid_on_outlined,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "No posts yet",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 3,
                            mainAxisSpacing: 3,
                          ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostDetailScreen(post: post),
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.grey[200],
                            child: Image.network(
                              post.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
