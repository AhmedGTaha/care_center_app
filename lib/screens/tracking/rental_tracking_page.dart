import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';

class RentalTrackingPage extends StatelessWidget {
  final bool isAdmin;

  const RentalTrackingPage({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final reservationService = ReservationService();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? "All Rentals" : "My Rental History"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Reservation>>(
        stream: isAdmin
            ? reservationService.getAllReservations()
            : reservationService.getUserReservations(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No rental history found."),
            );
          }

          final reservations = snapshot.data!;

          // Separate current and past rentals
          final current = reservations
              .where((r) =>
                  r.status == "approved" &&
                  (r.lifecycleStatus == "Reserved" ||
                      r.lifecycleStatus == "Checked Out"))
              .toList();

          final past = reservations
              .where((r) =>
                  r.status == "rejected" ||
                  r.lifecycleStatus == "Returned" ||
                  r.lifecycleStatus == "Maintenance")
              .toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: "Current Rentals"),
                    Tab(text: "History"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildRentalList(context, current, true, isAdmin),
                      _buildRentalList(context, past, false, isAdmin),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRentalList(
      BuildContext context, List<Reservation> rentals, bool isCurrent, bool isAdmin) {
    if (rentals.isEmpty) {
      return Center(
        child: Text(
          isCurrent ? "No current rentals" : "No rental history",
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rentals.length,
      itemBuilder: (_, index) {
        final res = rentals[index];
        final now = DateTime.now();
        final daysRemaining = res.endDate.difference(now).inDays;
        final isOverdue = daysRemaining < 0;

        return Card(
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

                const SizedBox(height: 8),

                // Dates
                _infoRow(Icons.calendar_today,
                    "Start: ${res.startDate.toString().split(' ')[0]}"),
                const SizedBox(height: 4),
                _infoRow(Icons.event,
                    "End: ${res.endDate.toString().split(' ')[0]}"),

                const SizedBox(height: 10),

                // Duration & Status
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOverdue ? Colors.red : Colors.blue,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isOverdue
                                  ? Icons.warning_amber
                                  : Icons.access_time,
                              color: isOverdue ? Colors.red : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOverdue
                                  ? "OVERDUE by ${daysRemaining.abs()} days"
                                  : "$daysRemaining days remaining",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isOverdue ? Colors.red : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Lifecycle: ${res.lifecycleStatus}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // User info (for admin)
                if (isAdmin)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("users")
                        .doc(res.userId)
                        .get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox();

                      final user = userSnap.data!;
                      final name = user["name"] ?? "Unknown";

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("Renter: $name"),
                      );
                    },
                  ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total: BD ${res.totalCost.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      "(${res.rentalDays} days × BD ${res.pricePerDay.toStringAsFixed(2)})",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case "approved":
        color = Colors.green;
        break;
      case "rejected":
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}