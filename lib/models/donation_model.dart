class Donation {
  String id;
  String userId;
  String itemName;
  String type;
  String description;
  String imagePath;
  int quantity;
  String condition;
  String status;

  Donation({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.type,
    required this.description,
    required this.imagePath,
    required this.quantity,
    required this.condition,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "itemName": itemName,
      "type": type,
      "description": description,
      "imagePath": imagePath,
      "quantity": quantity,
      "condition": condition,
      "status": status,
    };
  }

  factory Donation.fromMap(Map<String, dynamic> map, String documentId) {
    return Donation(
      id: documentId,
      userId: map["userId"] ?? "",
      itemName: map["itemName"] ?? "",
      type: map["type"] ?? "",
      description: map["description"] ?? "",
      imagePath: map["imagePath"] ?? "",
      quantity: map["quantity"] ?? 1,
      condition: map["condition"] ?? "Good",
      status: map["status"] ?? "pending",
    );
  }
}