import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import 'equipment_form.dart';

class AdminEquipmentList extends StatefulWidget {
  const AdminEquipmentList({super.key});

  @override
  State<AdminEquipmentList> createState() => _AdminEquipmentListState();
}

class _AdminEquipmentListState extends State<AdminEquipmentList> {
  final service = EquipmentService();
  final searchCtrl = TextEditingController();

  String searchQuery = "";
  String selectedType = "All";
  String selectedStatus = "All";
  bool showAvailableOnly = false;

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

  bool missing(String p) => p.isEmpty || !File(p).existsSync();

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

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      searchQuery = "";
      selectedType = "All";
      selectedStatus = "All";
      showAvailableOnly = false;
      searchCtrl.clear();
    });
  }

  void confirmDelete(BuildContext context, Equipment eq) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete ${eq.name}?"),
        content: const Text("Are you sure you want to delete this equipment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await service.deleteEquipment(eq);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${eq.name} deleted"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Equipment"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EquipmentForm()),
          );
        },
        child: const Icon(Icons.add),
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
                                  child: Text(
                                    status == "All"
                                        ? "All"
                                        : status[0].toUpperCase() +
                                            status.substring(1),
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

                const SizedBox(height: 8),

                // Toggle Filters
                FilterChip(
                  label: const Text("Available Only"),
                  selected: showAvailableOnly,
                  onSelected: (value) {
                    setState(() => showAvailableOnly = value);
                  },
                  selectedColor: Colors.green.shade100,
                ),
              ],
            ),
          ),

          // Equipment List
          Expanded(
            child: StreamBuilder<List<Equipment>>(
              stream: service.getEquipmentStream(),
              builder: (c, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allItems = s.data!;
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
                  itemBuilder: (_, i) {
                    final eq = filteredItems[i];
                    final placeholder = "assets/default_equipment.png";

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: missing(eq.imagePath)
                              ? Image.asset(placeholder,
                                  height: 50, width: 50, fit: BoxFit.cover)
                              : Image.file(File(eq.imagePath),
                                  height: 50, width: 50, fit: BoxFit.cover),
                        ),
                        title: Text(eq.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Type: ${eq.type}"),
                            Text(
                              "Stock: ${eq.quantity} | Price: BD ${eq.pricePerDay.toStringAsFixed(2)}/day",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EquipmentForm(equipment: eq),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => confirmDelete(context, eq),
                            ),
                          ],
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