import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';

class EquipmentDetails extends StatelessWidget {
  final Equipment eq;

  const EquipmentDetails({super.key, required this.eq});

  bool _invalidUrl(String url) {
    return url.isEmpty || url == "null" || !url.startsWith("http");
  }

  @override
  Widget build(BuildContext context) {
    final usePlaceholder = _invalidUrl(eq.imageUrl);

    return Scaffold(
      appBar: AppBar(title: Text(eq.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: usePlaceholder
                  ? Image.asset(
                      "assets/default_equipment.png",
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      eq.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Image.asset(
                          "assets/default_equipment.png",
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            Text(eq.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )),

            const SizedBox(height: 10),
            Text("Type: ${eq.type}"),
            Text("Condition: ${eq.condition}"),
            const SizedBox(height: 10),

            Text("BD ${eq.pricePerDay.toStringAsFixed(2)}/day",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),

            const SizedBox(height: 20),
            Text(eq.description),
          ],
        ),
      ),
    );
  }
}
