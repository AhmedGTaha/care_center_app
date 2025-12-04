import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import '../admin/equipment_form.dart';

class AdminEquipmentList extends StatelessWidget {
  AdminEquipmentList({super.key});

  final service = EquipmentService();

  bool _invalidUrl(String url) {
    return url.isEmpty || url == "null" || !url.startsWith("http");
  }

  void _confirmDelete(BuildContext context, Equipment eq) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Equipment"),
        content: Text("Are you sure you want to delete '${eq.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await service.deleteEquipment(eq.id);
              Navigator.pop(context); // close dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${eq.name} deleted successfully"),
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
      appBar: AppBar(
        title: const Text("Manage Equipment"),
        centerTitle: true,
      ),
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
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final items = snapshot.data!;

          if (items.isEmpty) {
            return const Center(child: Text("No equipment found"));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final eq = items[i];
              final usePlaceholder = _invalidUrl(eq.imageUrl);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: usePlaceholder
                        ? Image.asset(
                            "assets/default_equipment.png",
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            eq.imageUrl,
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Image.asset(
                                "assets/default_equipment.png",
                                height: 50,
                                width: 50,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                  ),
                  title: Text(eq.name),
                  subtitle: Text("BD ${eq.pricePerDay.toStringAsFixed(2)} / day"),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // ⭐ EDIT BUTTON — now correctly passes equipment
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EquipmentForm(
                                equipment: eq,  // IMPORTANT: pass real object
                              ),
                            ),
                          );
                        },
                      ),

                      // ⭐ DELETE BUTTON
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, eq),
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