import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import 'equipment_details.dart';

class RenterEquipmentList extends StatelessWidget {
  RenterEquipmentList({super.key});

  final service = EquipmentService();

  bool _invalidUrl(String url) {
    return url.isEmpty || url == "null" || !url.startsWith("http");
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

          final items = snapshot.data!
              .where((eq) => eq.status == "available" && eq.quantity > 0)
              .toList();

          if (items.isEmpty) {
            return const Center(
              child: Text("No equipment available right now."),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: .75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final eq = items[index];
              final price = eq.pricePerDay.toStringAsFixed(2);

              final usePlaceholder = _invalidUrl(eq.imageUrl);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EquipmentDetails(eq: eq),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: usePlaceholder
                            ? Image.asset(
                                "assets/default_equipment.png",
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                eq.imageUrl,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Image.asset(
                                    "assets/default_equipment.png",
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(eq.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 4),
                            Text(eq.type),
                            const SizedBox(height: 4),
                            Text("BD $price/day"),
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
