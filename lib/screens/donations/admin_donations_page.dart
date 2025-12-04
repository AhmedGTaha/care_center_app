import 'package:flutter/material.dart';
import '../../services/donation_service.dart';
import '../../models/donation_model.dart';
import '../../services/equipment_service.dart';
import '../../models/equipment_model.dart';

class AdminDonationsPage extends StatelessWidget {
  const AdminDonationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final donationService = DonationService();
    final equipmentService = EquipmentService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Donations"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Donation>>(
        stream: donationService.getAllDonations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final donations = snapshot.data!;
          if (donations.isEmpty) {
            return const Center(child: Text("No donations yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: donations.length,
            itemBuilder: (_, index) {
              final d = donations[index];

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.itemName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text("Type: ${d.type}"),
                      Text("Description: ${d.description}"),
                      const SizedBox(height: 6),
                      Image.network(d.imageUrl, height: 120),
                      const SizedBox(height: 10),

                      _statusBadge(d.status),
                      const SizedBox(height: 10),

                      if (d.status == "pending")
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await donationService.rejectDonation(d.id);
                              },
                              child: const Text("Reject",
                                  style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () async {
                                await donationService.approveDonation(d.id);

                                // ADD TO INVENTORY
                                await equipmentService.addEquipment(
                                  Equipment(
                                    id: DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString(),
                                    name: d.itemName,
                                    type: d.type,
                                    description: d.description,
                                    imageUrl: d.imageUrl,
                                    condition: "Used",
                                    quantity: 1,
                                    status: "available",
                                    pricePerDay: 0,
                                  ),
                                );
                              },
                              child: const Text("Accept"),
                            ),
                          ],
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

  Widget _statusBadge(String status) {
    Color color =
        status == "approved" ? Colors.green : status == "rejected" ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
