class Equipment {
  String id;
  String name;
  String type;
  String description;
  String imagePath;
  String condition;
  int quantity;
  String status;
  double pricePerDay;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.imagePath,
    required this.condition,
    required this.quantity,
    required this.status,
    required this.pricePerDay,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "type": type,
      "description": description,
      "imagePath": imagePath,
      "condition": condition,
      "quantity": quantity,
      "status": status,
      "pricePerDay": pricePerDay,
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map, String documentId) {
    return Equipment(
      id: documentId,
      name: map["name"] ?? "",
      type: map["type"] ?? "",
      description: map["description"] ?? "",
      imagePath: map["imagePath"] ?? "",
      condition: map["condition"] ?? "",
      quantity: map["quantity"] ?? 0,
      status: map["status"] ?? "available",
      pricePerDay: (map["pricePerDay"] is int)
          ? (map["pricePerDay"] as int).toDouble()
          : double.tryParse(map["pricePerDay"].toString()) ?? 0.0,
    );
  }
}
