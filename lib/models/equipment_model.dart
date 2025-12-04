class Equipment {
  String id;
  String name;
  String type;
  String description;
  String imageUrl;
  String condition;
  int quantity;
  String status; // available, rented, donated, maintenance
  double pricePerDay;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.imageUrl,
    required this.condition,
    required this.quantity,
    required this.status,
    required this.pricePerDay,
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "type": type,
      "description": description,
      "imageUrl": imageUrl,
      "condition": condition,
      "quantity": quantity,
      "status": status,
      "pricePerDay": pricePerDay,
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map, String documentId) {
    return Equipment(
      id: documentId,

      name: map["name"] ?? "Unknown",
      type: map["type"] ?? "Unknown",
      description: map["description"] ?? "No description",

      // Fallback handled in UI, not here
      imageUrl: map["imageUrl"] ?? "",

      condition: map["condition"] ?? "Unknown",

      quantity: (map["quantity"] is int)
          ? map["quantity"]
          : int.tryParse(map["quantity"].toString()) ?? 0,

      status: map["status"] ?? "available",

      pricePerDay: (map["pricePerDay"] is int)
          ? (map["pricePerDay"] as int).toDouble()
          : double.tryParse(map["pricePerDay"].toString()) ?? 0.0,
    );
  }
}
