import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';

class RenterReservationsPage extends StatelessWidget {
  const RenterReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final reservationService = ReservationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reservations"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Reservation>>(
        stream: reservationService.getUserReservations(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reservations = snapshot.data!;

          if (reservations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "You have no reservations yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reservations.length,
            itemBuilder: (_, index) {
              final res = reservations[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Equipment Name
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              res.equipmentName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _statusBadge(res.status),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Equipment Type
                      Text(
                        "Type: ${res.equipmentType}",
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const Divider(height: 20),

                      // Rental Details
                      _infoRow(Icons.calendar_today,
                          "Start: ${res.startDate.toString().split(' ')[0]}"),
                      const SizedBox(height: 6),
                      _infoRow(Icons.event,
                          "End: ${res.endDate.toString().split(' ')[0]}"),
                      const SizedBox(height: 6),
                      _infoRow(Icons.access_time,
                          "Duration: ${res.rentalDays} day${res.rentalDays > 1 ? 's' : ''}"),
                      const SizedBox(height: 6),
                      _infoRow(Icons.payments,
                          "Total: BD ${res.totalCost.toStringAsFixed(2)}"),

                      const SizedBox(height: 15),

                      // Lifecycle Progress Tracker
                      if (res.status == "approved")
                        _lifecycleTracker(res.lifecycleStatus),

                      const SizedBox(height: 12),

                      // Cancel Button (only for pending)
                      if (res.status == "pending")
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Cancel Reservation?"),
                                  content: const Text(
                                      "Are you sure you want to cancel this reservation?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("No"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      child: const Text("Yes, Cancel"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseFirestore.instance
                                    .collection("reservations")
                                    .doc(res.id)
                                    .delete();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Reservation cancelled successfully"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text(
                              "Cancel Reservation",
                              style: TextStyle(color: Colors.red),
                            ),
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

  Widget _statusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case "approved":
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case "rejected":
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _lifecycleTracker(String currentStatus) {
    final stages = ["Reserved", "Checked Out", "Returned", "Maintenance"];
    final currentIndex = stages.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Rental Progress:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(stages.length, (index) {
            final isActive = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Expanded(
              child: Column(
                children: [
                  // Circle indicator
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? Colors.green : Colors.grey.shade300,
                      border: Border.all(
                        color: isCurrent ? Colors.green : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isActive
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 5),
                  // Label
                  Text(
                    stages[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}