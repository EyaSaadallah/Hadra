import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';

class FollowListScreen extends StatelessWidget {
  final String uid;
  final String title; // "Followers" or "Following"
  final Stream<List<UserModel>> userStream;

  const FollowListScreen({
    super.key,
    required this.uid,
    required this.title,
    required this.userStream,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<UserModel>>(
        stream: userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No $title found"));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      (user.profilePic != null && user.profilePic!.isNotEmpty)
                      ? NetworkImage(user.profilePic!)
                      : null,
                  child: (user.profilePic == null || user.profilePic!.isEmpty)
                      ? Text(user.name?[0].toUpperCase() ?? '?')
                      : null,
                ),
                title: Text(user.username ?? user.name ?? 'Unknown'),
                subtitle: Text(user.name ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(uid: user.uid),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
