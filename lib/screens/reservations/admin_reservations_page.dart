import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import '../../services/equipment_service.dart';
import '../../services/notification_service.dart';

class AdminReservationsPage extends StatelessWidget {
  const AdminReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reservationService = ReservationService();
    final equipmentService = EquipmentService();
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Reservations"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Reservation>>(
        stream: reservationService.getAllReservations(),
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
                    "No reservations yet.",
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
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Equipment & User Info
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  res.equipmentName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  res.equipmentType,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          _statusBadge(res.status),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Get User Info
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection("users")
                            .doc(res.userId)
                            .get(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData) {
                            return const Text("Loading user...");
                          }

                          final user = userSnap.data!;
                          final name = user["name"] ?? "Unknown";
                          final phone = user["phone"] ?? "N/A";

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Renter: $name",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text("Phone: $phone"),
                              ],
                            ),
                          );
                        },
                      ),

                      const Divider(height: 20),

                      // Rental Details
                      _infoRow(
                          Icons.calendar_today,
                          "Start: ${res.startDate.toString().split(' ')[0]}"),
                      const SizedBox(height: 6),
                      _infoRow(Icons.event,
                          "End: ${res.endDate.toString().split(' ')[0]}"),
                      const SizedBox(height: 6),
                      _infoRow(Icons.access_time,
                          "Duration: ${res.rentalDays} days"),
                      const SizedBox(height: 6),
                      _infoRow(Icons.payments,
                          "Total: BD ${res.totalCost.toStringAsFixed(2)}"),

                      const SizedBox(height: 12),

                      // Lifecycle Status
                      if (res.status == "approved")
                        _lifecycleDropdown(context, res, reservationService),

                      const SizedBox(height: 12),

                      // Action Buttons
                      if (res.status == "pending")
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              onPressed: () {
                                _reject(reservationService, notificationService,
                                    res.id, res.userId, res.equipmentName, context);
                              },
                              icon: const Icon(Icons.cancel),
                              label: const Text("Reject"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                _approve(
                                    reservationService,
                                    equipmentService,
                                    notificationService,
                                    res,
                                    context);
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text("Approve"),
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

  Widget _lifecycleDropdown(
      BuildContext context, Reservation res, ReservationService service) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes, color: Colors.green),
          const SizedBox(width: 10),
          const Text(
            "Lifecycle:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<String>(
              value: res.lifecycleStatus,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                    value: "Reserved", child: Text("Reserved")),
                DropdownMenuItem(
                    value: "Checked Out", child: Text("Checked Out")),
                DropdownMenuItem(
                    value: "Returned", child: Text("Returned")),
                DropdownMenuItem(
                    value: "Maintenance", child: Text("Maintenance")),
              ],
              onChanged: (newStatus) async {
                if (newStatus != null) {
                  await service.updateLifecycleStatus(res.id, newStatus);

                  // If returned, increase equipment quantity back
                  if (newStatus == "Returned") {
                    final eqDoc = await FirebaseFirestore.instance
                        .collection("equipment")
                        .doc(res.equipmentId)
                        .get();

                    if (eqDoc.exists) {
                      int qty = eqDoc["quantity"];
                      await FirebaseFirestore.instance
                          .collection("equipment")
                          .doc(res.equipmentId)
                          .update({"quantity": qty + 1});
                    }
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Status updated to $newStatus"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _reject(
      ReservationService service,
      NotificationService notificationService,
      String reservationId,
      String userId,
      String equipmentName,
      BuildContext context) async {
    await service.rejectReservation(reservationId);

    // SEND NOTIFICATION TO RENTER
    await notificationService.createNotification(
      userId: userId,
      title: "Reservation Rejected",
      message: "Your reservation for $equipmentName has been rejected",
      type: "reservation_rejected",
      reservationId: reservationId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reservation Rejected & User Notified"),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _approve(
      ReservationService service,
      EquipmentService eqService,
      NotificationService notificationService,
      Reservation res,
      BuildContext context) async {
    // Approve reservation
    await service.approveReservation(res.id);

    // Decrease equipment quantity
    final eqDoc =
        await eqService.db.collection("equipment").doc(res.equipmentId).get();

    if (eqDoc.exists) {
      int qty = eqDoc["quantity"];
      if (qty > 0) {
        await eqService.db
            .collection("equipment")
            .doc(res.equipmentId)
            .update({"quantity": qty - 1});
      }
    }

    // SEND NOTIFICATION TO RENTER
    await notificationService.createNotification(
      userId: res.userId,
      title: "Reservation Approved",
      message:
          "Your reservation for ${res.equipmentName} has been approved! Pickup from: ${res.startDate.toString().split(' ')[0]}",
      type: "reservation_approved",
      reservationId: res.id,
      equipmentId: res.equipmentId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reservation Approved & User Notified"),
        backgroundColor: Colors.green,
      ),
    );
  }
}