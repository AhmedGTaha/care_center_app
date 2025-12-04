import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/donation_model.dart';

class DonationService {
  final db = FirebaseFirestore.instance;

  Future<String> uploadDonationImage(File file) async {
    final name = "donation_${DateTime.now().millisecondsSinceEpoch}";
    final ref = FirebaseStorage.instance.ref().child("donations/$name");
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> submitDonation({
    required String userId,
    required String itemName,
    required String type,
    required String description,
    required String imageUrl,
  }) async {
    await db.collection("donations").add({
      "userId": userId,
      "itemName": itemName,
      "type": type,
      "description": description,
      "imageUrl": imageUrl,
      "status": "pending",
      "createdAt": Timestamp.now(),
    });
  }

  //Stream for admin
  Stream<List<Donation>> getAllDonations() {
    return db.collection("donations").orderBy("createdAt", descending: true).snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Donation.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> approveDonation(String id) async {
    await db.collection("donations").doc(id).update({"status": "approved"});
  }

  Future<void> rejectDonation(String id) async {
    await db.collection("donations").doc(id).update({"status": "rejected"});
  }
}
