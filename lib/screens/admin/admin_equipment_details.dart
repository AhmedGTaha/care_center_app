import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import '../../services/notification_service.dart';
import 'equipment_form.dart';

class AdminEquipmentDetails extends StatefulWidget {
  final Equipment eq;

  const AdminEquipmentDetails({super.key, required this.eq});

  @override
  State<AdminEquipmentDetails> createState() => _AdminEquipmentDetailsState();
}

class _AdminEquipmentDetailsState extends State<AdminEquipmentDetails> {
  final equipmentService = EquipmentService();
  final notificationService = NotificationService();
  bool loading = false;
  String currentStatus = "";

  @override
  void initState() {
    super.initState();
    currentStatus = widget.eq.status;
  }

  bool _isInvalidImage(String p) => p.isEmpty || !File(p).existsSync();

  Future<void> _updateStatus(String newStatus) async {
    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection("equipment")
          .doc(widget.eq.id)
          .update({"status": newStatus});

      // SEND NOTIFICATION TO ADMINS WHEN STATUS CHANGES TO MAINTENANCE
      if (newStatus == "maintenance") {
        await notificationService.notifyMaintenanceNeeded(
          widget.eq.id,
          widget.eq.name,
        );
      }

      setState(() {
        currentStatus = newStatus;
        loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status updated to ${newStatus.toUpperCase()}"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating status: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text("Delete Equipment"),
          ],
        ),
        content: Text(
          "Are you sure you want to delete ${widget.eq.name}?\n\nThis action cannot be undone.",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEquipment();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEquipment() async {
    setState(() => loading = true);

    try {
      await equipmentService.deleteEquipment(widget.eq);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.eq.name} deleted successfully"),
            backgroundColor: Colors.red,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => loading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting equipment: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentForm(equipment: widget.eq),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eq.name),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Equipment Image
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

                  // Equipment Name
                  Text(
                    widget.eq.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Type Badge
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

                  // Tags Display
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

                  // Description
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

                  // Details Card
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status Management Section
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
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
                              "Equipment Status",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Current Status:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusColor(currentStatus).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor(currentStatus),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getStatusIcon(currentStatus),
                                color: _getStatusColor(currentStatus),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                currentStatus.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(currentStatus),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Change Status:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: currentStatus,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "available",
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  SizedBox(width: 10),
                                  Text("Available"),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: "rented",
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_cart, color: Colors.orange, size: 20),
                                  SizedBox(width: 10),
                                  Text("Rented"),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: "donated",
                              child: Row(
                                children: [
                                  Icon(Icons.volunteer_activism, color: Colors.blue, size: 20),
                                  SizedBox(width: 10),
                                  Text("Donated"),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: "maintenance",
                              child: Row(
                                children: [
                                  Icon(Icons.build, color: Colors.red, size: 20),
                                  SizedBox(width: 10),
                                  Text("Under Maintenance"),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (newStatus) {
                            if (newStatus != null && newStatus != currentStatus) {
                              _showStatusChangeConfirmation(newStatus);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showDeleteConfirmation,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            "Delete",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            side: const BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToEdit,
                          icon: const Icon(Icons.edit),
                          label: const Text(
                            "Edit",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  void _showStatusChangeConfirmation(String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 10),
            Text("Change Status"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Change equipment status from ${currentStatus.toUpperCase()} to ${newStatus.toUpperCase()}?",
              style: const TextStyle(fontSize: 16),
            ),
            if (newStatus == "maintenance") ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "All admins will be notified",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(newStatus);
            },
            child: const Text("Confirm"),
          ),
        ],
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "available":
        return Colors.green;
      case "rented":
        return Colors.orange;
      case "donated":
        return Colors.blue;
      case "maintenance":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "available":
        return Icons.check_circle;
      case "rented":
        return Icons.shopping_cart;
      case "donated":
        return Icons.volunteer_activism;
      case "maintenance":
        return Icons.build;
      default:
        return Icons.info;
    }
  }
}