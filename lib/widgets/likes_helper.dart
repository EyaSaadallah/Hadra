import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../screens/profile_screen.dart';

class LikesHelper {
  static void showLikes(BuildContext context, List<String> uids) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  // Handle for dragging
                  Container(
                    margin: const EdgeInsets.all(12),
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
                      "Likes",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: uids.isEmpty
                        ? const Center(child: Text("No likes yet"))
                        : StreamBuilder<List<UserModel>>(
                            stream: UserService().getUsersFromUids(uids),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text("Error: ${snapshot.error}"),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text("No users found"),
                                );
                              }

                              final users = snapshot.data!;

                              return ListView.builder(
                                controller: scrollController,
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  final String currentUserId =
                                      AuthService().currentUser?.uid ?? '';
                                  final bool isCurrentUser =
                                      user.uid == currentUserId;

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
                                          ? Text(
                                              user.name?[0].toUpperCase() ??
                                                  '?',
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      user.username ?? user.name ?? 'Unknown',
                                    ),
                                    subtitle: Text(user.name ?? ''),
                                    trailing: isCurrentUser
                                        ? null
                                        : StreamBuilder<bool>(
                                            stream: UserService().isFollowing(
                                              currentUserId,
                                              user.uid,
                                            ),
                                            builder: (context, followSnapshot) {
                                              final bool isFollowing =
                                                  followSnapshot.data ?? false;
                                              return ElevatedButton(
                                                onPressed: () {
                                                  if (isFollowing) {
                                                    UserService().unfollowUser(
                                                      currentUserId,
                                                      user.uid,
                                                    );
                                                  } else {
                                                    UserService().followUser(
                                                      currentUserId,
                                                      user.uid,
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isFollowing
                                                      ? Colors.grey[200]
                                                      : Colors.blue,
                                                  foregroundColor: isFollowing
                                                      ? Colors.black
                                                      : Colors.white,
                                                  elevation: 0,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  minimumSize: const Size(
                                                    0,
                                                    30,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  isFollowing
                                                      ? "Following"
                                                      : "Follow",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProfileScreen(uid: user.uid),
                                        ),
                                      );
                                    },
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
      },
    );
  }
}
