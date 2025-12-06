import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String userId;
  final String equipmentId;
  final String equipmentName;
  final String equipmentType;
  final DateTime startDate;
  final DateTime endDate;
  final String status; 
  final String lifecycleStatus;
  final int rentalDays;
  final double totalCost;
  final double pricePerDay;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.userId,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.lifecycleStatus,
    required this.rentalDays,
    required this.totalCost,
    required this.pricePerDay,
    required this.createdAt,
  });

  factory Reservation.fromMap(Map<String, dynamic> map, String docId) {
    return Reservation(
      id: docId,
      userId: map["userId"] ?? "",
      equipmentId: map["equipmentId"] ?? "",
      equipmentName: map["equipmentName"] ?? "",
      equipmentType: map["equipmentType"] ?? "",
      startDate: (map["startDate"] as Timestamp).toDate(),
      endDate: (map["endDate"] as Timestamp).toDate(),
      status: map["status"] ?? "pending",
      lifecycleStatus: map["lifecycleStatus"] ?? "Reserved",
      rentalDays: map["rentalDays"] ?? 0,
      totalCost: (map["totalCost"] is int)
          ? (map["totalCost"] as int).toDouble()
          : (map["totalCost"] as double? ?? 0.0),
      pricePerDay: (map["pricePerDay"] is int)
          ? (map["pricePerDay"] as int).toDouble()
          : (map["pricePerDay"] as double? ?? 0.0),
      createdAt: (map["createdAt"] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "equipmentId": equipmentId,
      "equipmentName": equipmentName,
      "equipmentType": equipmentType,
      "startDate": Timestamp.fromDate(startDate),
      "endDate": Timestamp.fromDate(endDate),
      "status": status,
      "lifecycleStatus": lifecycleStatus,
      "rentalDays": rentalDays,
      "totalCost": totalCost,
      "pricePerDay": pricePerDay,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }
}