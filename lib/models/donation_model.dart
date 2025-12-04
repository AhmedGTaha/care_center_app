class Donation {
  String id;
  String itemName;
  String type;
  String description;
  String imagePath;   // ⭐ local file path instead of URL
  String status;

  Donation({
    required this.id,
    required this.itemName,
    required this.type,
    required this.description,
    required this.imagePath,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      "itemName": itemName,
      "type": type,
      "description": description,
      "imagePath": imagePath,
      "status": status,
    };
  }

  factory Donation.fromMap(Map<String, dynamic> map, String documentId) {
    return Donation(
      id: documentId,
      itemName: map["itemName"] ?? "",
      type: map["type"] ?? "",
      description: map["description"] ?? "",
      imagePath: map["imagePath"] ?? "",
      status: map["status"] ?? "pending",
    );
  }
}