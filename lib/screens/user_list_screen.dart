import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';

import 'chat_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: const InputDecoration(
                  hintText: "Search conversations...",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
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

          var users = snapshot.data!;

          if (_searchQuery.isNotEmpty) {
            users = users.where((user) {
              final name = user.name?.toLowerCase() ?? "";
              final username = user.username?.toLowerCase() ?? "";
              return name.contains(_searchQuery) ||
                  username.contains(_searchQuery);
            }).toList();
          }

          if (users.isEmpty && _searchQuery.isNotEmpty) {
            return const Center(child: Text("No conversations found"));
          }

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
