import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final db = FirebaseFirestore.instance;

  // Stream all reservations
  Stream<List<Reservation>> getAllReservations() {
    return db.collection("reservations").orderBy("createdAt", descending: true).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  // Approve reservation
  Future<void> approveReservation(String id) async {
    await db.collection("reservations").doc(id).update({"status": "approved"});
  }

  // Reject reservation
  Future<void> rejectReservation(String id) async {
    await db.collection("reservations").doc(id).update({"status": "rejected"});
  }

  // Delete reservation (optional)
  Future<void> deleteReservation(String id) async {
    await db.collection("reservations").doc(id).delete();
  }

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

}
