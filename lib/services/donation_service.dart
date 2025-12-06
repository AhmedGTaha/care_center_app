import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation_model.dart';
import 'notification_service.dart';

class DonationService {
  final db = FirebaseFirestore.instance;
  final notificationService = NotificationService();

  Future<void> submitDonation({
    required String userId,
    required String itemName,
    required String type,
    required String description,
    required String imagePath,
    required int quantity,
    required String condition,
  }) async {
    await db.collection("donations").add({
      "userId": userId,
      "itemName": itemName,
      "type": type,
      "description": description,
      "imagePath": imagePath,
      "quantity": quantity,
      "condition": condition,
      "status": "pending",
      "createdAt": Timestamp.now(),
    });

    final userDoc = await db.collection("users").doc(userId).get();
    final donorName = userDoc.data()?["name"] ?? "A user";

    await notificationService.notifyAdminAboutDonation(donorName, itemName);
  }

  Stream<List<Donation>> getAllDonations() {
    return db
        .collection("donations")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Donation.fromMap(d.data(), d.id)).toList());
  }

  Future<void> approveDonation(String id) async {
    await db.collection("donations").doc(id).update({"status": "approved"});
  }

  Future<void> rejectDonation(String id) async {
    await db.collection("donations").doc(id).update({"status": "rejected"});
  }
}