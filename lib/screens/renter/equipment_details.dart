import 'dart:io';

import 'package:care_center_app/screens/renter/reserve_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/equipment_model.dart';

class EquipmentDetails extends StatefulWidget {
  final Equipment eq;

  const EquipmentDetails({super.key, required this.eq});

  @override
  State<EquipmentDetails> createState() => _EquipmentDetailsState();
}

class _EquipmentDetailsState extends State<EquipmentDetails> {
  bool isGuest = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _checkIfGuest();
  }

  Future<void> _checkIfGuest() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        setState(() {
          isGuest = true;
          loading = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      setState(() {
        isGuest = !userDoc.exists || user.uid == "guest_user";
        loading = false;
      });
    } catch (e) {
      debugPrint("Error checking user status: $e");
      setState(() {
        isGuest = true;
        loading = false;
      });
    }
  }

  bool _isInvalidImage(String p) => p.isEmpty || !File(p).existsSync();

  void _showGuestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 10),
            Text("Login Required"),
          ],
        ),
        content: const Text(
          "You need to create an account or log in to reserve equipment.\n\n"
          "Guest users can browse equipment and make donations, but cannot make reservations.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.eq.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.eq.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isInvalidImage(widget.eq.imagePath)
                  ? Image.asset(
                      "assets/default_equipment.png",
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(widget.eq.imagePath),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),

            const SizedBox(height: 20),

            Text(
              widget.eq.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Text(
                widget.eq.type,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),

            const SizedBox(height: 15),

            if (widget.eq.tags.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tags",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.eq.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Colors.blue.shade50,
                        avatar: const Icon(Icons.label, size: 16),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 15),
                ],
              ),

            const Text(
              "Description",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.eq.description.isEmpty
                  ? "No description available"
                  : widget.eq.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    _detailRow(
                      Icons.build,
                      "Condition",
                      widget.eq.condition,
                    ),
                    const Divider(),
                    _detailRow(
                      Icons.inventory,
                      "Quantity Available",
                      "${widget.eq.quantity}",
                    ),
                    const Divider(),
                    // NEW: Location Display
                    if (widget.eq.location.isNotEmpty) ...[
                      _detailRow(
                        Icons.location_on,
                        "Location",
                        widget.eq.location,
                      ),
                      const Divider(),
                    ],
                    _detailRow(
                      Icons.payments,
                      "Price Per Day",
                      widget.eq.pricePerDay == 0
                          ? "FREE (Donated)"
                          : "BD ${widget.eq.pricePerDay.toStringAsFixed(2)}",
                    ),
                    const Divider(),
                    _detailRow(
                      Icons.info_outline,
                      "Status",
                      widget.eq.status[0].toUpperCase() +
                          widget.eq.status.substring(1),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (isGuest)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.orange.shade700, size: 30),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Login Required",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Create an account to reserve equipment",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showGuestDialog,
                      icon: const Icon(Icons.info_outline),
                      label: const Text(
                        "Why can't I reserve?",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: BorderSide(color: Colors.orange.shade700, width: 2),
                        foregroundColor: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.eq.quantity > 0
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReservePage(eq: widget.eq),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    widget.eq.quantity > 0
                        ? "Reserve Equipment"
                        : "Currently Unavailable",
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ),

            const SizedBox(height: 15),

            if (!isGuest && widget.eq.quantity > 0)
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 15),
          Text(
            "$label:",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}