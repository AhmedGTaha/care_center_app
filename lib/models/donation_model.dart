import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  final String id;
  final String userId;
  final String itemName;
  final String type;
  final String description;
  final String imageUrl;
  final DateTime createdAt;
  final String status; // pending, approved, rejected

  Donation({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.type,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    required this.status,
  });

  factory Donation.fromMap(Map<String, dynamic> map, String id) {
    return Donation(
      id: id,
      userId: map["userId"],
      itemName: map["itemName"],
      type: map["type"],
      description: map["description"],
      imageUrl: map["imageUrl"],
      createdAt: (map["createdAt"] as Timestamp).toDate(),
      status: map["status"],
    );
  }
}
