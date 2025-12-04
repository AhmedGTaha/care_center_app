import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import 'equipment_form.dart';

class AdminEquipmentList extends StatelessWidget {
  AdminEquipmentList({super.key});

  final service = EquipmentService();

  bool missing(String p) => p.isEmpty || !File(p).existsSync();

  void confirmDelete(BuildContext context, Equipment eq) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete ${eq.name}?"),
        content: const Text("Are you sure you want to delete this equipment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await service.deleteEquipment(eq);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${eq.name} deleted"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Equipment")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EquipmentForm()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Equipment>>(
        stream: service.getEquipmentStream(),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());

          final items = s.data!;
          if (items.isEmpty) return const Center(child: Text("No equipment found"));

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final eq = items[i];
              final placeholder = "assets/default_equipment.png";

              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: missing(eq.imagePath)
                        ? Image.asset(placeholder, height: 50, width: 50)
                        : Image.file(File(eq.imagePath),
                            height: 50, width: 50, fit: BoxFit.cover),
                  ),
                  title: Text(eq.name),
                  subtitle: Text("BD ${eq.pricePerDay}/day"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EquipmentForm(equipment: eq),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmDelete(context, eq),
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