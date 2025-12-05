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
  bool checkingAvailability = false;
  bool isAvailable = false;
  int availableQuantity = 0;
  double totalCost = 0.0;
  int rentalDays = 0;

  @override
  void initState() {
    super.initState();
    _checkCurrentAvailability();
  }

  // Check current availability
  Future<void> _checkCurrentAvailability() async {
    setState(() => checkingAvailability = true);

    final snapshot = await FirebaseFirestore.instance
        .collection("equipment")
        .doc(widget.eq.id)
        .get();

    if (snapshot.exists) {
      final qty = snapshot.data()?["quantity"] ?? 0;
      setState(() {
        availableQuantity = qty;
        isAvailable = qty > 0;
        checkingAvailability = false;
      });
    }
  }

  // Calculate rental duration
  void _calculateDuration() {
    if (startDate != null && endDate != null) {
      final days = endDate!.difference(startDate!).inDays + 1;
      setState(() {
        rentalDays = days;
        totalCost = days * widget.eq.pricePerDay;
      });
    }
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      helpText: "Select Start Date",
    );

    if (picked != null) {
      setState(() {
        startDate = picked;

        // Reset end date if it is before start date
        if (endDate != null && endDate!.isBefore(startDate!)) {
          endDate = null;
        }
        _calculateDuration();
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
      helpText: "Select End Date",
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
        _calculateDuration();
      });
    }
  }

  // Check availability for selected date range
  Future<bool> _checkDateAvailability() async {
    if (startDate == null || endDate == null) return false;

    // Query overlapping reservations
    final snapshot = await FirebaseFirestore.instance
        .collection("reservations")
        .where("equipmentId", isEqualTo: widget.eq.id)
        .where("status", isEqualTo: "approved")
        .get();

    int reservedCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final resStart = (data["startDate"] as Timestamp).toDate();
      final resEnd = (data["endDate"] as Timestamp).toDate();

      // Check if dates overlap
      if (!(endDate!.isBefore(resStart) || startDate!.isAfter(resEnd))) {
        reservedCount++;
      }
    }

    // Check if equipment is available
    return (availableQuantity - reservedCount) > 0;
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

    // Check availability for selected dates
    final available = await _checkDateAvailability();

    if (!available) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Equipment not available for selected dates"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Save reservation
    await FirebaseFirestore.instance.collection("reservations").add({
      "equipmentId": widget.eq.id,
      "equipmentName": widget.eq.name,
      "equipmentType": widget.eq.type,
      "userId": uid,
      "startDate": Timestamp.fromDate(startDate!),
      "endDate": Timestamp.fromDate(endDate!),
      "status": "pending",
      "rentalDays": rentalDays,
      "totalCost": totalCost,
      "pricePerDay": widget.eq.pricePerDay,
      "createdAt": Timestamp.now(),
      "lifecycleStatus": "Reserved", // Reserved → Checked Out → Returned → Maintenance
    });

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reservation submitted successfully!"),
        backgroundColor: Colors.green,
      ),
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
      body: checkingAvailability
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Equipment Info Card
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.eq.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("Type: ${widget.eq.type}"),
                          Text("Condition: ${widget.eq.condition}"),
                          Text(
                            "Price: BD ${widget.eq.pricePerDay.toStringAsFixed(2)}/day",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Availability Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAvailable ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAvailable
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: isAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isAvailable
                              ? "Available ($availableQuantity in stock)"
                              : "Currently Unavailable",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Date Selection Section
                  const Text(
                    "Select Rental Period",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // START DATE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isAvailable ? pickStartDate : null,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        startDate == null
                            ? "Pick Start Date"
                            : "Start: ${startDate!.toString().split(' ')[0]}",
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // END DATE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isAvailable ? pickEndDate : null,
                      icon: const Icon(Icons.event),
                      label: Text(
                        endDate == null
                            ? "Pick End Date"
                            : "End: ${endDate!.toString().split(' ')[0]}",
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Rental Summary
                  if (startDate != null && endDate != null)
                    Card(
                      elevation: 2,
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Rental Summary",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Duration:"),
                                Text(
                                  "$rentalDays day${rentalDays > 1 ? 's' : ''}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Price per day:"),
                                Text(
                                  "BD ${widget.eq.pricePerDay.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Cost:",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "BD ${totalCost.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 25),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (loading || !isAvailable)
                          ? null
                          : submitReservation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Confirm Reservation",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Info Text
                  const Text(
                    "Your reservation will be pending until approved by admin.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}