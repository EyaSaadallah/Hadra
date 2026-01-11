import 'package:flutter/material.dart';
import 'package:hadra/models/post_model.dart';
import 'package:hadra/services/auth_service.dart';
import 'package:hadra/services/post_service.dart';
import 'package:hadra/widgets/post_widget.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hadra",
          style: TextStyle(
            fontFamily:
                'Pacifico', // Assuming user might want a stylish logo font, or just use bold
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_outlined),
            onPressed: () {
              // Navigate to messages
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: _postService.getFeedPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No posts yet. Follow people to see posts!"),
            );
          }

          final posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostWidget(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}
