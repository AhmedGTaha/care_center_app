import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import 'equipment_details.dart';

class RenterEquipmentList extends StatelessWidget {
  RenterEquipmentList({super.key});

  final service = EquipmentService();

  bool _isInvalidImage(String path) {
    return path.isEmpty || !File(path).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Equipment"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Equipment>>(
        stream: service.getEquipmentStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text("No equipment available."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final eq = items[index];
              final invalid = _isInvalidImage(eq.imagePath);

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: invalid
                        ? Image.asset(
                            "assets/default_equipment.png",
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(eq.imagePath),
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                  ),

                  title: Text(
                    eq.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("BD ${eq.pricePerDay.toStringAsFixed(2)} per day"),

                  trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.blue),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EquipmentDetails(eq: eq),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}