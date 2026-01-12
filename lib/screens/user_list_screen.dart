import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';

import 'chat_screen.dart';

class UserListScreen extends StatelessWidget {
  UserListScreen({super.key});

  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: StreamBuilder<List<UserModel>>(
        stream: _chatService.getChatUsers(currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No messages yet"));
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
                trailing: StreamBuilder<int>(
                  stream: _chatService.getUnreadMessageCount(
                    currentUser?.uid ?? '',
                    user.uid,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == 0) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${snapshot.data}',
                        style: const TextStyle(
                          color: Colors.white,
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
                      builder: (context) => ChatScreen(receiverUser: user),
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
