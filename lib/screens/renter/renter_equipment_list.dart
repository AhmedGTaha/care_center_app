import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import 'equipment_details.dart';

class RenterEquipmentList extends StatelessWidget {
  RenterEquipmentList({super.key});

  final service = EquipmentService();

  bool missing(String p) => p.isEmpty || !File(p).existsSync();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Equipment")),
      body: StreamBuilder<List<Equipment>>(
        stream: service.getEquipmentStream(),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());

          final items = s.data!
              .where((e) => e.status == "available" && e.quantity > 0)
              .toList();

          if (items.isEmpty) return const Center(child: Text("No equipment available"));

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemBuilder: (_, i) {
              final eq = items[i];

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EquipmentDetails(eq: eq)),
                ),
                child: Card(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: missing(eq.imagePath)
                            ? Image.asset("assets/default_equipment.png",
                                height: 110, width: double.infinity, fit: BoxFit.cover)
                            : Image.file(File(eq.imagePath),
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(eq.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(eq.type),
                            Text("BD ${eq.pricePerDay}/day"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
