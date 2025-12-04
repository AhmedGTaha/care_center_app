import 'package:flutter/material.dart';
import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import '../../services/equipment_service.dart';

class AdminReservationsPage extends StatelessWidget {
  const AdminReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reservationService = ReservationService();
    final equipmentService = EquipmentService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Reservations"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Reservation>>(
        stream: reservationService.getAllReservations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final reservations = snapshot.data!;
          if (reservations.isEmpty) {
            return const Center(child: Text("No reservations yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reservations.length,
            itemBuilder: (_, index) {
              final res = reservations[index];

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(res.equipmentName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text("From: ${res.startDate.toString().split(' ')[0]}"),
                      Text("To:   ${res.endDate.toString().split(' ')[0]}"),
                      const SizedBox(height: 6),

                      _statusBadge(res.status),

                      const SizedBox(height: 12),

                      if (res.status == "pending")
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () {
                                _reject(reservationService, res.id, context);
                              },
                              child: const Text("Reject"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                _approve(reservationService, equipmentService, res, context);
                              },
                              child: const Text("Approve"),
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
      decoration:
          BoxDecoration(color: color.withOpacity(.2), borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _reject(ReservationService service, String id, BuildContext context) async {
    await service.rejectReservation(id);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Reservation Rejected")));
  }

  void _approve(
      ReservationService service,
      EquipmentService eqService,
      Reservation res,
      BuildContext context) async {
    // approve reservation
    await service.approveReservation(res.id);

    // update equipment quantity
    final eqDoc = await eqService.db.collection("equipment").doc(res.equipmentId).get();

    if (eqDoc.exists) {
      int qty = eqDoc["quantity"];
      if (qty > 0) {
        await eqService.db
            .collection("equipment")
            .doc(res.equipmentId)
            .update({"quantity": qty - 1});
      }
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Reservation Approved")));
  }
}