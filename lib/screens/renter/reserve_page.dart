import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/equipment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservePage extends StatefulWidget {
  final Equipment eq;

  const ReservePage({super.key, required this.eq});

  @override
  State<ReservePage> createState() => _ReservePageState();
}

class _ReservePageState extends State<ReservePage> {
  DateTime? startDate;
  DateTime? endDate;
  bool loading = false;

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  Future<void> submitReservation() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select both dates")));
      return;
    }

    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection("reservations").add({
      "equipmentId": widget.eq.id,
      "equipmentName": widget.eq.name,
      "userId": uid,
      "startDate": startDate!,
      "endDate": endDate!,
      "status": "pending",
      "createdAt": Timestamp.now(),
    });

    setState(() => loading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reserve Equipment")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickStartDate,
              child: Text(
                  startDate == null ? "Pick Start Date" : startDate.toString()),
            ),
            ElevatedButton(
              onPressed: pickEndDate,
              child: Text(
                  endDate == null ? "Pick End Date" : endDate.toString()),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : submitReservation,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Reservation"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
