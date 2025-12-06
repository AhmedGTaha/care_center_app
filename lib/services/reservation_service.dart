import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final db = FirebaseFirestore.instance;

  Stream<List<Reservation>> getAllReservations() {
    return db
        .collection("reservations")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Reservation>> getUserReservations(String userId) {
    return db
        .collection("reservations")
        .where("userId", isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final reservations = snapshot.docs
              .map((doc) => Reservation.fromMap(doc.data(), doc.id))
              .toList();
          
          reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return reservations;
        });
  }

  Future<void> approveReservation(String id) async {
    await db.collection("reservations").doc(id).update({
      "status": "approved",
      "lifecycleStatus": "Reserved",
    });
  }

  Future<void> rejectReservation(String id) async {
    await db.collection("reservations").doc(id).update({
      "status": "rejected",
    });
  }

  Future<void> updateLifecycleStatus(String id, String newStatus) async {
    await db.collection("reservations").doc(id).update({
      "lifecycleStatus": newStatus,
    });
  }

  Future<void> deleteReservation(String id) async {
    await db.collection("reservations").doc(id).delete();
  }

  Future<bool> checkAvailability({
    required String equipmentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await db
        .collection("reservations")
        .where("equipmentId", isEqualTo: equipmentId)
        .where("status", isEqualTo: "approved")
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final resStart = (data["startDate"] as Timestamp).toDate();
      final resEnd = (data["endDate"] as Timestamp).toDate();

      if (!(endDate.isBefore(resStart) || startDate.isAfter(resEnd))) {
        return false;
      }
    }

    return true;
  }

  Future<Map<String, int>> getReservationStats() async {
    final snapshot = await db.collection("reservations").get();

    int pending = 0;
    int approved = 0;
    int rejected = 0;

    for (var doc in snapshot.docs) {
      final status = doc.data()["status"];
      if (status == "pending") pending++;
      if (status == "approved") approved++;
      if (status == "rejected") rejected++;
    }

    return {
      "pending": pending,
      "approved": approved,
      "rejected": rejected,
      "total": snapshot.docs.length,
    };
  }
}