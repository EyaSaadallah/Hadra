import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/imagekit_service.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  final _captionController = TextEditingController();
  bool _isLoading = false;

  final PostService _postService = PostService();
  final ImageKitService _imageKitService = ImageKitService();
  final AuthService _authService = AuthService();

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final String postId = const Uuid().v4();
      final String fileName = "post_${postId}.jpg";

      // 1. Upload to ImageKit
      final String? imageUrl = await _imageKitService.uploadImage(
        _image!,
        fileName,
        folder: 'hadra/posts',
      );

      if (imageUrl != null) {
        // 2. Save to Firestore
        final post = PostModel(
          id: postId,
          ownerUid: user.uid,
          imageUrl: imageUrl,
          caption: _captionController.text,
          timestamp: DateTime.now(),
          likes: [],
          commentCount: 0,
        );

        await _postService.createPost(post);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post shared successfully!")),
          );
          // Reset
          setState(() {
            _image = null;
            _captionController.clear();
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to upload image");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "New Post",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_image != null)
            TextButton(
              onPressed: _isLoading ? null : _uploadPost,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      "Share",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey[200],
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Tap to select an image",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _captionController,
                decoration: const InputDecoration(
                  hintText: "Write a caption...",
                  border: InputBorder.none,
                ),
                maxLines: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
