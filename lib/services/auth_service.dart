import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Convert phone number to email format for Firebase Auth
  String _phoneToEmail(String phone) {
    // Remove + and special characters, then add domain
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return '$cleanPhone@hadra.app';
  }

  // Hash password for storage
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sign Up with Phone and Password
  Future<UserCredential?> signUp({
    required String phoneNumber,
    required String password,
    required String name,
  }) async {
    try {
      String email = _phoneToEmail(phoneNumber);

      // Create user with email/password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user to Firestore
      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          phoneNumber: phoneNumber,
          name: name,
          password: _hashPassword(password),
        );
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Error signing up: ${e.message}");
      rethrow;
    } catch (e) {
      print("Error signing up: $e");
      return null;
    }
  }

  // Sign In with Phone and Password
  Future<UserCredential?> signIn({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      String email = _phoneToEmail(phoneNumber);

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Error signing in: ${e.message}");
      rethrow;
    } catch (e) {
      print("Error signing in: $e");
      return null;
    }
  }

  // Get current user's data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("Error getting user data: $e");
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfile({
    String? name,
    String? profilePic,
    String? address,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (profilePic != null) data['profilePic'] = profilePic;
      if (address != null) data['address'] = address;

      if (data.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(data);
      }
    } catch (e) {
      print("Error updating profile: $e");
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;
}
