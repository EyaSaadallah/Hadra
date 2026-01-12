import 'package:flutter/material.dart';
import 'package:hadra/models/user_model.dart';
import 'package:hadra/models/post_model.dart';
import 'package:hadra/services/auth_service.dart';
import 'package:hadra/services/post_service.dart';
import 'package:hadra/services/user_service.dart';
import 'package:hadra/screens/edit_profile_screen.dart';
import 'package:hadra/screens/post_detail_screen.dart';
import 'package:hadra/screens/follow_list_screen.dart';
import 'package:hadra/screens/chat_screen.dart';
import 'package:hadra/widgets/account_switch_helper.dart';

class ProfileScreen extends StatelessWidget {
  final String uid;
  ProfileScreen({super.key, required this.uid});

  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    String currentUserId = _authService.currentUser?.uid ?? '';
    bool isMe = currentUserId == uid;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<UserModel?>(
          stream: _userService.getUserData(uid),
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
        stream: _userService.getUserData(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("User not found"));
          }
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
                        backgroundColor: Colors.grey[200],
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
                            _buildStatColumn("Posts", user.postsCount, null),
                            StreamBuilder<int>(
                              stream: _userService.getFollowerCount(uid),
                              builder: (context, countSnapshot) {
                                return _buildStatColumn(
                                  "Followers",
                                  countSnapshot.data ?? user.followersCount,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FollowListScreen(
                                          uid: user.uid,
                                          title: "Followers",
                                          userStream: _userService.getFollowers(
                                            user.uid,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            StreamBuilder<int>(
                              stream: _userService.getFollowingCount(uid),
                              builder: (context, countSnapshot) {
                                return _buildStatColumn(
                                  "Following",
                                  countSnapshot.data ?? user.followingCount,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FollowListScreen(
                                          uid: user.uid,
                                          title: "Following",
                                          userStream: _userService.getFollowing(
                                            user.uid,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
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

                // Action Buttons (Edit Profile or Follow/Unfollow)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: isMe
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditProfileScreen(),
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
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  AccountSwitchHelper.showAccountSwitcher(
                                    context,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.swap_horiz,
                                  color: Colors.black,
                                ),
                                label: const Text(
                                  "Switch Account",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        )
                      : StreamBuilder<bool>(
                          stream: _userService.isFollowing(currentUserId, uid),
                          builder: (context, followSnapshot) {
                            bool following = followSnapshot.data ?? false;
                            return StreamBuilder<bool>(
                              stream: _userService.isFollowing(
                                uid,
                                currentUserId,
                              ),
                              builder: (context, followedBySnapshot) {
                                bool isFollowedByThem =
                                    followedBySnapshot.data ?? false;

                                String buttonText = "Follow";
                                if (following) {
                                  buttonText = "Unfollow";
                                } else if (isFollowedByThem) {
                                  buttonText = "Follow Back";
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (following) {
                                            _userService.unfollowUser(
                                              currentUserId,
                                              uid,
                                            );
                                          } else {
                                            _userService.followUser(
                                              currentUserId,
                                              uid,
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: following
                                              ? Colors.grey[200]
                                              : Colors.blue,
                                          foregroundColor: following
                                              ? Colors.black
                                              : Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(buttonText),
                                      ),
                                    ),
                                    if (following) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChatScreen(
                                                      receiverUser: user,
                                                    ),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            "Message",
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
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

  Widget _buildStatColumn(String label, int count, VoidCallback? onTap) {
    // Ensure we don't display negative numbers in case of legacy data corruption
    final displayCount = count < 0 ? 0 : count;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            displayCount.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
