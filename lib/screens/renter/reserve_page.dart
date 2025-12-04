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
      setState(() {
        startDate = picked;

        // Reset end date if it is before start date
        if (endDate != null && endDate!.isBefore(startDate!)) {
          endDate = null;
        }
      });
    }
  }

  Future<void> pickEndDate() async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a start date first")),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: startDate!,
      firstDate: startDate!,
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  Future<void> submitReservation() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select both dates")),
      );
      return;
    }

    if (endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End date cannot be before start date")),
      );
      return;
    }

    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Save reservation
    await FirebaseFirestore.instance.collection("reservations").add({
      "equipmentId": widget.eq.id,
      "equipmentName": widget.eq.name,
      "userId": uid,
      "startDate": startDate,
      "endDate": endDate,
      "status": "pending",
      "createdAt": Timestamp.now(),
    });

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reservation submitted")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reserve ${widget.eq.name}"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // START DATE BUTTON
            ElevatedButton(
              onPressed: pickStartDate,
              child: Text(
                startDate == null
                    ? "Pick Start Date"
                    : "Start: ${startDate!.toLocal()}".split(".")[0],
              ),
            ),

            const SizedBox(height: 10),

            // END DATE BUTTON
            ElevatedButton(
              onPressed: pickEndDate,
              child: Text(
                endDate == null
                    ? "Pick End Date"
                    : "End: ${endDate!.toLocal()}".split(".")[0],
              ),
            ),

            const SizedBox(height: 25),

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