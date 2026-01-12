import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'account_storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Hash password for storage
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sign Up with Email and Password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      // Create user with email/password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user to Firestore
      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
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

  // Sign In with Email and Password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save account credentials for account switching
      if (userCredential.user != null) {
        final accountStorage = AccountStorageService();
        final userData = await getCurrentUserData();
        await accountStorage.saveAccount(
          email: email,
          password: password,
          name: userData?.name,
          profilePic: userData?.profilePic,
        );
      }

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
    String? username,
    String? profilePic,
    String? bio,
    String? address,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (username != null) data['username'] = username;
      if (profilePic != null) data['profilePic'] = profilePic;
      if (bio != null) data['bio'] = bio;
      if (address != null) data['address'] = address;

      if (data.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(data);

        // Update saved account info if name or profilePic changed
        if (name != null || profilePic != null) {
          final accountStorage = AccountStorageService();
          if (user.email != null) {
            await accountStorage.updateAccountInfo(
              email: user.email!,
              name: name,
              profilePic: profilePic,
            );
          }
        }
      }
    } catch (e) {
      print("Error updating profile: $e");
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;

  Stream<UserModel?> get currentUserStream {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? UserModel.fromMap(doc.data() as Map<String, dynamic>)
              : null,
        );
  }
}
