import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';

class EquipmentDetails extends StatelessWidget {
  final Equipment eq;

  const EquipmentDetails({super.key, required this.eq});

  bool missing(String p) => p.isEmpty || !File(p).existsSync();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(eq.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            missing(eq.imagePath)
                ? Image.asset("assets/default_equipment.png",
                    height: 200, fit: BoxFit.cover)
                : Image.file(File(eq.imagePath),
                    height: 200, fit: BoxFit.cover),

            const SizedBox(height: 20),
            Text(eq.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Type: ${eq.type}"),
            const SizedBox(height: 10),
            Text(eq.description),
            const SizedBox(height: 10),
            Text("Condition: ${eq.condition}"),
            const SizedBox(height: 10),
            Text("Quantity: ${eq.quantity}"),
            const SizedBox(height: 10),
            Text("Price Per Day: BD ${eq.pricePerDay}"),
          ],
        ),
      ),
    );
  }
}
