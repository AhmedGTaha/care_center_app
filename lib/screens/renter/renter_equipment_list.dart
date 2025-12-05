import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import 'equipment_details.dart';

class RenterEquipmentList extends StatefulWidget {
  const RenterEquipmentList({super.key});

  @override
  State<RenterEquipmentList> createState() => _RenterEquipmentListState();
}

class _RenterEquipmentListState extends State<RenterEquipmentList> {
  final service = EquipmentService();
  final searchCtrl = TextEditingController();

  String searchQuery = "";
  String selectedType = "All";
  String selectedStatus = "All";
  bool showAvailableOnly = false;
  bool showDonatedOnly = false;

  List<String> equipmentTypes = [
    "All",
    "Wheelchair",
    "Walker",
    "Crutches",
    "Hospital Bed",
    "Oxygen Machine",
    "Medical Monitor",
    "Mobility Scooter",
    "Hoist / Lift",
    "Chair",
    "Other",
  ];

  List<String> statusOptions = [
    "All",
    "available",
    "rented",
    "donated",
    "maintenance",
  ];

  bool _isInvalidImage(String path) {
    return path.isEmpty || !File(path).existsSync();
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

  List<Equipment> _applyFilters(List<Equipment> items) {
    return items.where((eq) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!eq.name.toLowerCase().contains(query) &&
            !eq.type.toLowerCase().contains(query) &&
            !eq.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Type filter
      if (selectedType != "All" && eq.type != selectedType) {
        return false;
      }

      // Status filter
      if (selectedStatus != "All" && eq.status != selectedStatus) {
        return false;
      }

      // Available only filter
      if (showAvailableOnly && eq.quantity <= 0) {
        return false;
      }

      // Donated only filter (price = 0 means donated)
      if (showDonatedOnly && eq.pricePerDay > 0) {
        return false;
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      searchQuery = "";
      selectedType = "All";
      selectedStatus = "All";
      showAvailableOnly = false;
      showDonatedOnly = false;
      searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Browse Equipment"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: "Search equipment...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchCtrl.clear();
                            searchQuery = "";
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),

          // Filters Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Filters",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text("Reset"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Type Dropdown
                Row(
                  children: [
                    const Text("Type: "),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        items: equipmentTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedType = value!);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Status Dropdown
                Row(
                  children: [
                    const Text("Status: "),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        items: statusOptions
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Row(
                                    children: [
                                      if (status != "All") ...[
                                        Icon(
                                          _getStatusIcon(status),
                                          size: 16,
                                          color: _getStatusColor(status),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        status == "All"
                                            ? "All"
                                            : status[0].toUpperCase() +
                                                status.substring(1),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedStatus = value!);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Equipment List
          Expanded(
            child: StreamBuilder<List<Equipment>>(
              stream: service.getEquipmentStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allItems = snapshot.data!;
                final filteredItems = _applyFilters(allItems);

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No equipment found",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try adjusting your filters",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredItems.length,
                  itemBuilder: (_, index) {
                    final eq = filteredItems[index];
                    final invalid = _isInvalidImage(eq.imagePath);
                    final isAvailable = eq.quantity > 0 && eq.status == "available";
                    final isDonated = eq.pricePerDay == 0;

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EquipmentDetails(eq: eq),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: invalid
                                    ? Image.asset(
                                        "assets/default_equipment.png",
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(eq.imagePath),
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      ),
                              ),

                              const SizedBox(width: 12),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      eq.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      eq.type,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.inventory,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${eq.quantity} available",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        // Price/Donated Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDonated
                                                ? Colors.blue.shade50
                                                : Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isDonated
                                                  ? Colors.blue
                                                  : Colors.green,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            isDonated
                                                ? "DONATED"
                                                : "BD ${eq.pricePerDay.toStringAsFixed(2)}/day",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDonated
                                                  ? Colors.blue
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),

                                        // Status Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(eq.status)
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: _getStatusColor(eq.status),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getStatusIcon(eq.status),
                                                size: 12,
                                                color: _getStatusColor(eq.status),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                eq.status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusColor(eq.status),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Availability Badge
                                        if (isAvailable)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  size: 12,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Can Reserve",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Arrow Icon
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }
}