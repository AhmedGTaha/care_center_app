import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/donation_model.dart';
import '../../models/equipment_model.dart';
import '../../services/donation_service.dart';
import '../../services/equipment_service.dart';
import '../../services/notification_service.dart';
import '../admin/equipment_form.dart';

class AdminDonationsPage extends StatelessWidget {
  AdminDonationsPage({super.key});

  final donationService = DonationService();
  final equipmentService = EquipmentService();
  final notificationService = NotificationService();

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
                      // ITEM INFO
                      Text(
                        d.itemName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      Text("Type: ${d.type}"),
                      Text("Quantity: ${d.quantity}"),

                      const SizedBox(height: 6),

                      // DONOR INFO - FIXED FOR GUESTS
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection("donations")
                            .doc(d.id)
                            .get(),
                        builder: (context, donationSnap) {
                          if (!donationSnap.hasData) {
                            return const Text(
                              "Loading donor info...",
                              style: TextStyle(fontStyle: FontStyle.italic),
                            );
                          }

                          final donationData = donationSnap.data!.data() as Map<String, dynamic>?;
                          
                          // Check if this is a guest donation
                          final isGuest = donationData?["isGuest"] ?? false;
                          
                          if (isGuest) {
                            // For guest donations, use the stored donor info
                            final guestName = donationData?["donorName"] ?? "Guest";
                            final guestEmail = donationData?["donorEmail"] ?? "guest@example.com";
                            final guestPhone = donationData?["donorPhone"] ?? "N/A";

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.orange,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 14,
                                            color: Colors.orange.shade800,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "GUEST DONATION",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Donated by: $guestName",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text("Email: $guestEmail"),
                                Text("Phone: $guestPhone"),
                                const SizedBox(height: 10),
                              ],
                            );
                          } else {
                            // For registered user donations, fetch from users collection
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(d.userId)
                                  .get(),
                              builder: (context, userSnap) {
                                if (!userSnap.hasData) {
                                  return const Text(
                                    "Loading user info...",
                                    style: TextStyle(fontStyle: FontStyle.italic),
                                  );
                                }

                                if (!userSnap.data!.exists) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Text(
                                        "Donated by: Unknown User (ID: ${d.userId})",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const Text("User data not found"),
                                      const SizedBox(height: 10),
                                    ],
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
                            );
                          }
                        },
                      ),

                      // IMAGE
                      if (d.imagePath.isNotEmpty && File(d.imagePath).existsSync())
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(d.imagePath),
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/default_equipment.png',
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(height: 10),

                      // STATUS BADGE
                      _statusBadge(d.status),

                      const SizedBox(height: 10),

                      // ACTION BUTTONS
                      if (d.status == "pending")
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Reject button
                            TextButton(
                              onPressed: () async {
                                await donationService.rejectDonation(d.id);

                                // SEND NOTIFICATION TO DONOR (IF NOT GUEST)
                                if (d.userId != "guest_user") {
                                  await notificationService.createNotification(
                                    userId: d.userId,
                                    title: "Donation Rejected",
                                    message:
                                        "Your donation of ${d.itemName} has been rejected",
                                    type: "donation_rejected",
                                  );
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Donation Rejected & User Notified"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
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

                                // SEND NOTIFICATION TO DONOR (IF NOT GUEST)
                                if (d.userId != "guest_user") {
                                  await notificationService.createNotification(
                                    userId: d.userId,
                                    title: "Donation Approved",
                                    message:
                                        "Thank you! Your donation of ${d.itemName} has been approved and added to our inventory",
                                    type: "donation_approved",
                                  );
                                }

                                // Convert donation → Equipment
                                final equipment = Equipment(
                                  id: "",
                                  name: d.itemName,
                                  type: d.type,
                                  description: d.description,
                                  imagePath: d.imagePath,
                                  condition: d.condition,
                                  quantity: d.quantity,
                                  status: "donated", // AUTOMATICALLY SET TO "donated"
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