import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/donation_model.dart';
import '../../models/equipment_model.dart';
import '../../services/donation_service.dart';
import '../../services/equipment_service.dart';
import '../admin/equipment_form.dart';

class AdminDonationsPage extends StatelessWidget {
  AdminDonationsPage({super.key});

  final donationService = DonationService();
  final equipmentService = EquipmentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Donations"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Donation>>(
        stream: donationService.getAllDonations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

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
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ------------------------------
                      // ITEM INFO
                      // ------------------------------
                      Text(
                        d.itemName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      Text("Type: ${d.type}"),
                      Text("Quantity: ${d.quantity}"),

                      const SizedBox(height: 6),

                      // ------------------------------
                      // DONOR INFO
                      // ------------------------------
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection("users")
                            .doc(d.userId)
                            .get(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData) {
                            return const Text(
                              "Loading donor info...",
                              style: TextStyle(fontStyle: FontStyle.italic),
                            );
                          }

                          final user = userSnap.data!;
                          final name = user["name"] ?? "Unknown User";
                          final email = user["email"] ?? "No Email";
                          final phone = user["phone"] ?? "No Phone";

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                "Donated by: $name",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text("Email: $email"),
                              Text("Phone: $phone"),
                              const SizedBox(height: 10),
                            ],
                          );
                        },
                      ),

                      // ------------------------------
                      // IMAGE
                      // ------------------------------
                      if (d.imagePath.isNotEmpty && File(d.imagePath).existsSync())
                        Image.file(
                          File(d.imagePath),
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      else
                        Image.asset(
                          'assets/default_equipment.png',  // Default placeholder
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),

                      const SizedBox(height: 10),

                      // ------------------------------
                      // STATUS BADGE
                      // ------------------------------
                      _statusBadge(d.status),

                      const SizedBox(height: 10),

                      // ------------------------------
                      // ACTION BUTTONS
                      // ------------------------------
                      if (d.status == "pending")
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Reject button
                            TextButton(
                              onPressed: () async {
                                await donationService.rejectDonation(d.id);
                              },
                              child: const Text(
                                "Reject",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Accept button
                            ElevatedButton(
                              onPressed: () async {
                                await donationService.approveDonation(d.id);

                                // Convert donation → Equipment
                                final equipment = Equipment(
                                  id: "",
                                  name: d.itemName,
                                  type: d.type,
                                  description: d.description,
                                  imagePath: d.imagePath,
                                  condition: d.condition,
                                  quantity: d.quantity,
                                  status: "available",
                                  pricePerDay: 0,
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EquipmentForm(
                                      equipment: equipment,
                                      isFromDonation: true,
                                    ),
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

  // ------------------------------
  // STATUS BADGE
  // ------------------------------
  Widget _statusBadge(String status) {
    final color = status == "approved"
        ? Colors.green
        : status == "rejected"
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}