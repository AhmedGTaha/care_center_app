import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/defaults.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> register({
  required String name,
  required String email,
  required String password,
  required String phone,
  required String role,
  required String avatarUrl,
}) async {
  try {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final String savedAvatar =
        avatarUrl.isNotEmpty ? avatarUrl : defaultAvatarPath;

    final bool canDonate = role == "renter";

    await _db.collection("users").doc(cred.user!.uid).set({
      "uid": cred.user!.uid,
      "name": name,
      "email": email,
      "phone": phone,
      "role": role,
      "avatarUrl": savedAvatar,
      "canDonate": canDonate,
      "createdAt": Timestamp.now(),
    });

    return null;
  } catch (e) {
    return e.toString();
  }
}


  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String?> getUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection("users").doc(uid).get();
    return doc.data()?["role"];
  }
}