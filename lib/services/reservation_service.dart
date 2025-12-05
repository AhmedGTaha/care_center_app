import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final db = FirebaseFirestore.instance;

  // Stream all reservations (for admin)
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

  // Stream user reservations (for renter)
  Stream<List<Reservation>> getUserReservations(String userId) {
    return db
        .collection("reservations")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reservation.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Approve reservation
  Future<void> approveReservation(String id) async {
    await db.collection("reservations").doc(id).update({
      "status": "approved",
      "lifecycleStatus": "Reserved",
    });
  }

  // Reject reservation
  Future<void> rejectReservation(String id) async {
    await db.collection("reservations").doc(id).update({
      "status": "rejected",
    });
  }

  // Update lifecycle status (Reserved → Checked Out → Returned → Maintenance)
  Future<void> updateLifecycleStatus(String id, String newStatus) async {
    await db.collection("reservations").doc(id).update({
      "lifecycleStatus": newStatus,
    });
  }

  // Delete reservation
  Future<void> deleteReservation(String id) async {
    await db.collection("reservations").doc(id).delete();
  }

  // Check if equipment is available for date range
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

    // Check for overlapping reservations
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final resStart = (data["startDate"] as Timestamp).toDate();
      final resEnd = (data["endDate"] as Timestamp).toDate();

      // If dates overlap, equipment is not available
      if (!(endDate.isBefore(resStart) || startDate.isAfter(resEnd))) {
        return false;
      }
    }

    return true;
  }

  // Get reservation statistics (for reports)
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