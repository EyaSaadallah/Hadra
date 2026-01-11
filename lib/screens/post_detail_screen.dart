import 'package:flutter/material.dart';
import 'package:hadra/models/post_model.dart';
import 'package:hadra/widgets/post_widget.dart';

class PostDetailScreen extends StatelessWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Post",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(child: PostWidget(post: post)),
    );
  }
}
