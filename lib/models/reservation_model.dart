import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String userId;
  final String equipmentId;
  final String equipmentName;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // pending, approved, rejected

  Reservation({
    required this.id,
    required this.userId,
    required this.equipmentId,
    required this.equipmentName,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Reservation.fromMap(Map<String, dynamic> map, String docId) {
    return Reservation(
      id: docId,
      userId: map["userId"],
      equipmentId: map["equipmentId"],
      equipmentName: map["equipmentName"],
      startDate: (map["startDate"] as Timestamp).toDate(),
      endDate: (map["endDate"] as Timestamp).toDate(),
      status: map["status"],
    );
  }
}
