import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/equipment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservePage extends StatefulWidget {
  final Equipment eq;

  const ReservePage({super.key, required this.eq});

  @override
  State<ReservePage> createState() => _ReservePageEnhancedState();
}

class _ReservePageEnhancedState extends State<ReservePage> {
  DateTime? startDate;
  DateTime? endDate;
  bool loading = false;
  bool checkingAvailability = false;
  bool isAvailable = false;
  int availableQuantity = 0;
  double totalCost = 0.0;
  int rentalDays = 0;
  
  int suggestedDays = 7;
  int minDays = 1;
  int maxDays = 30;
  bool isTrustedUser = false;
  int userRentalHistory = 0;

  @override
  void initState() {
    super.initState();
    _checkCurrentAvailability();
    _loadUserHistory();
    _calculateSuggestedDuration();
  }

  Future<void> _loadUserHistory() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      
      final snapshot = await FirebaseFirestore.instance
          .collection("reservations")
          .where("userId", isEqualTo: uid)
          .where("status", isEqualTo: "approved")
          .where("lifecycleStatus", isEqualTo: "Returned")
          .get();

      setState(() {
        userRentalHistory = snapshot.docs.length;
        isTrustedUser = userRentalHistory >= 3;
      });

      _calculateSuggestedDuration();
    } catch (e) {
      debugPrint("Error loading user history: $e");
    }
  }

  void _calculateSuggestedDuration() {
    switch (widget.eq.type) {
      case "Wheelchair":
        suggestedDays = 14;
        minDays = 3;
        maxDays = 30;
        break;
      case "Walker":
        suggestedDays = 21;
        minDays = 7;
        maxDays = 60;
        break;
      case "Crutches":
        suggestedDays = 10;
        minDays = 3;
        maxDays = 30;
        break;
      case "Hospital Bed":
        suggestedDays = 30;
        minDays = 7;
        maxDays = 90;
        break;
      case "Oxygen Machine":
        suggestedDays = 30;
        minDays = 14;
        maxDays = 90;
        break;
      default:
        suggestedDays = 7;
        minDays = 1;
        maxDays = 30;
    }

    if (isTrustedUser) {
      maxDays = (maxDays * 1.5).toInt();
      debugPrint("Trusted user detected. Extended max duration to $maxDays days");
    }

    setState(() {});
  }

  void _autoSuggestEndDate() {
    if (startDate != null) {
      setState(() {
        endDate = startDate!.add(Duration(days: suggestedDays));
        _calculateDuration();
      });
    }
  }

  Future<void> _checkCurrentAvailability() async {
    setState(() => checkingAvailability = true);

    try {
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
    } catch (e) {
      setState(() {
        checkingAvailability = false;
        isAvailable = false;
      });
    }
  }

  void _calculateDuration() {
    if (startDate != null && endDate != null) {
      final days = endDate!.difference(startDate!).inDays + 1;
      
      if (days < minDays || days > maxDays) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Rental duration must be between $minDays and $maxDays days"
            ),
            backgroundColor: Colors.orange,
          ),
        );
        
        endDate = startDate!.add(Duration(days: suggestedDays));
        _calculateDuration();
        return;
      }
      
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
        // Reset end date
        endDate = null;
      });
      
      _autoSuggestEndDate();
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
      initialDate: endDate ?? startDate!.add(Duration(days: suggestedDays)),
      firstDate: startDate!.add(Duration(days: minDays - 1)),
      lastDate: startDate!.add(Duration(days: maxDays)),
      helpText: "Select End Date",
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
        _calculateDuration();
      });
    }
  }

  void _selectQuickDuration(int days) {
    if (startDate != null) {
      setState(() {
        endDate = startDate!.add(Duration(days: days));
        _calculateDuration();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select start date first")),
      );
    }
  }

  Future<bool> _checkDateAvailability() async {
    if (startDate == null || endDate == null) return false;

    try {
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

        if (!(endDate!.isBefore(resStart) || startDate!.isAfter(resEnd))) {
          reservedCount++;
        }
      }

      return (availableQuantity - reservedCount) > 0;
    } catch (e) {
      return false;
    }
  }

  Future<void> submitReservation() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select both dates")),
      );
      return;
    }

    setState(() => loading = true);

    try {
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
        "lifecycleStatus": "Reserved",
      });

      setState(() => loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reservation submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
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

                  if (isTrustedUser)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "✨ Trusted User: You have $userRentalHistory completed rentals. Extended rental period available!",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

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
                          isAvailable ? Icons.check_circle : Icons.cancel,
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

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 10),
                            Text(
                              "Rental Period Guidelines",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "• Suggested duration: $suggestedDays days",
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          "• Minimum: $minDays days",
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          "• Maximum: $maxDays days",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Select Rental Period",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

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

                  if (startDate != null) ...[
                    const Text(
                      "Quick Select Duration:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (suggestedDays >= minDays && suggestedDays <= maxDays)
                          ElevatedButton(
                            onPressed: () => _selectQuickDuration(suggestedDays),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: Text("$suggestedDays days (Suggested)"),
                          ),
                        if (7 >= minDays && 7 <= maxDays)
                          OutlinedButton(
                            onPressed: () => _selectQuickDuration(7),
                            child: const Text("7 days"),
                          ),
                        if (14 >= minDays && 14 <= maxDays)
                          OutlinedButton(
                            onPressed: () => _selectQuickDuration(14),
                            child: const Text("14 days"),
                          ),
                        if (30 >= minDays && 30 <= maxDays)
                          OutlinedButton(
                            onPressed: () => _selectQuickDuration(30),
                            child: const Text("30 days"),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isAvailable ? pickEndDate : null,
                      icon: const Icon(Icons.event),
                      label: Text(
                        endDate == null
                            ? "Pick End Date (or use quick select)"
                            : "End: ${endDate!.toString().split(' ')[0]}",
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

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

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (loading || !isAvailable) ? null : submitReservation,
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