import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';
import 'edit_profile_screen.dart';

class UserListScreen extends StatelessWidget {
  UserListScreen({super.key});

  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hadra - Users"),
        actions: [
          // Current User Profile Image
          StreamBuilder<UserModel?>(
            stream: _authService.currentUserStream,
            builder: (context, snapshot) {
              final user = snapshot.data;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        (user?.profilePic != null &&
                            user!.profilePic!.isNotEmpty)
                        ? NetworkImage(user.profilePic!)
                        : null,
                    child:
                        (user?.profilePic == null || user!.profilePic!.isEmpty)
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => _authService.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _chatService.getUsers(currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found"));
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
                title: Text(user.name ?? 'Unknown'),
                subtitle: Text(user.email),
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
