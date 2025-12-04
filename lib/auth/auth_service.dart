import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/defaults.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Upload avatar
  Future<String> uploadAvatar(File file) async {
    final fileName = "avatar_${DateTime.now().millisecondsSinceEpoch}";
    final ref = FirebaseStorage.instance.ref().child("avatars/$fileName");
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Register user
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? avatarUrl,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userAvatar =
          (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : defaultAvatarUrl;

      final canDonate = role == "renter";

      await _db.collection("users").doc(cred.user!.uid).set({
        "uid": cred.user!.uid,
        "name": name,
        "email": email,
        "phone": phone,
        "role": role,
        "avatarUrl": userAvatar,
        "canDonate": canDonate,
        "createdAt": Timestamp.now(),
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Login
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Fetch role
  Future<String?> getUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection("users").doc(uid).get();
    return doc.data()?["role"];
  }
}