import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool loading = true;
  
  // Statistics
  int totalEquipment = 0;
  int availableEquipment = 0;
  int rentedEquipment = 0;
  int maintenanceEquipment = 0;
  
  int totalReservations = 0;
  int pendingReservations = 0;
  int approvedReservations = 0;
  int rejectedReservations = 0;
  
  int totalDonations = 0;
  int pendingDonations = 0;
  int approvedDonations = 0;
  
  int overdueRentals = 0;
  
  List<Map<String, dynamic>> mostRentedEquipment = [];
  List<Map<String, dynamic>> mostDonatedTypes = [];
  List<Map<String, dynamic>> maintenanceRecords = [];
  List<Map<String, dynamic>> overdueList = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => loading = true);

    await Future.wait([
      _loadEquipmentStats(),
      _loadReservationStats(),
      _loadDonationStats(),
      _loadMostRentedEquipment(),
      _loadMostDonatedTypes(),
      _loadMaintenanceRecords(),
      _loadOverdueRentals(),
    ]);

    setState(() => loading = false);
  }

  Future<void> _loadEquipmentStats() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("equipment")
        .get();

    totalEquipment = snapshot.docs.length;
    availableEquipment = snapshot.docs
        .where((doc) => doc.data()["status"] == "available")
        .length;
    rentedEquipment = snapshot.docs
        .where((doc) => doc.data()["status"] == "rented")
        .length;
    maintenanceEquipment = snapshot.docs
        .where((doc) => doc.data()["status"] == "maintenance")
        .length;
  }

  Future<void> _loadReservationStats() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("reservations")
        .get();

    totalReservations = snapshot.docs.length;
    pendingReservations = snapshot.docs
        .where((doc) => doc.data()["status"] == "pending")
        .length;
    approvedReservations = snapshot.docs
        .where((doc) => doc.data()["status"] == "approved")
        .length;
    rejectedReservations = snapshot.docs
        .where((doc) => doc.data()["status"] == "rejected")
        .length;
  }

  Future<void> _loadDonationStats() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("donations")
        .get();

    totalDonations = snapshot.docs.length;
    pendingDonations = snapshot.docs
        .where((doc) => doc.data()["status"] == "pending")
        .length;
    approvedDonations = snapshot.docs
        .where((doc) => doc.data()["status"] == "approved")
        .length;
  }

  Future<void> _loadMostRentedEquipment() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("reservations")
        .where("status", isEqualTo: "approved")
        .get();

    // Count rentals per equipment
    Map<String, Map<String, dynamic>> rentalCount = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final equipmentId = data["equipmentId"] ?? "";
      final equipmentName = data["equipmentName"] ?? "Unknown";
      
      if (rentalCount.containsKey(equipmentId)) {
        rentalCount[equipmentId]!["count"]++;
      } else {
        rentalCount[equipmentId] = {
          "name": equipmentName,
          "count": 1,
        };
      }
    }

    // Convert to list and sort
    mostRentedEquipment = rentalCount.entries
        .map((e) => {
              "name": e.value["name"],
              "count": e.value["count"],
            })
        .toList();
    
    mostRentedEquipment.sort((a, b) => b["count"].compareTo(a["count"]));
    
    // Keep top 10
    if (mostRentedEquipment.length > 10) {
      mostRentedEquipment = mostRentedEquipment.sublist(0, 10);
    }
  }

  Future<void> _loadMostDonatedTypes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("donations")
        .get();

    // Count donations per type
    Map<String, int> donationCount = {};
    
    for (var doc in snapshot.docs) {
      final type = doc.data()["type"] ?? "Other";
      donationCount[type] = (donationCount[type] ?? 0) + 1;
    }

    // Convert to list and sort
    mostDonatedTypes = donationCount.entries
        .map((e) => {
              "type": e.key,
              "count": e.value,
            })
        .toList();
    
    mostDonatedTypes.sort((a, b) => b["count"].compareTo(a["count"]));
  }

  Future<void> _loadMaintenanceRecords() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("reservations")
        .where("lifecycleStatus", isEqualTo: "Maintenance")
        .get();

    maintenanceRecords = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        "equipmentName": data["equipmentName"] ?? "Unknown",
        "equipmentType": data["equipmentType"] ?? "Unknown",
        "startDate": (data["startDate"] as Timestamp).toDate(),
      };
    }).toList();
  }

  Future<void> _loadOverdueRentals() async {
    final now = DateTime.now();
    final snapshot = await FirebaseFirestore.instance
        .collection("reservations")
        .where("status", isEqualTo: "approved")
        .get();

    overdueList = [];
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final lifecycleStatus = data["lifecycleStatus"] ?? "";
      
      if (lifecycleStatus == "Returned" || lifecycleStatus == "Maintenance") {
        continue;
      }
      
      final endDate = (data["endDate"] as Timestamp).toDate();
      
      if (endDate.isBefore(now)) {
        final daysOverdue = now.difference(endDate).inDays;
        overdueList.add({
          "equipmentName": data["equipmentName"] ?? "Unknown",
          "endDate": endDate,
          "daysOverdue": daysOverdue,
          "userId": data["userId"] ?? "",
        });
      }
    }
    
    overdueRentals = overdueList.length;
    overdueList.sort((a, b) => b["daysOverdue"].compareTo(a["daysOverdue"]));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Reports & Statistics"),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports & Statistics"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            // Overview Section
            _buildSectionTitle("Overview"),
            _buildOverviewCards(),
            
            const SizedBox(height: 20),
            
            // Equipment Statistics
            _buildSectionTitle("Equipment Statistics"),
            _buildEquipmentStats(),
            
            const SizedBox(height: 20),
            
            // Rental Analytics
            _buildSectionTitle("Rental Analytics"),
            _buildReservationStats(),
            
            const SizedBox(height: 20),
            
            // Most Rented Equipment
            _buildSectionTitle("Most Frequently Rented Equipment"),
            _buildMostRentedList(),
            
            const SizedBox(height: 20),
            
            // Donation Statistics
            _buildSectionTitle("Donation Statistics"),
            _buildDonationStats(),
            
            const SizedBox(height: 20),
            
            // Most Donated Types
            _buildSectionTitle("Most Donated Equipment Types"),
            _buildMostDonatedList(),
            
            const SizedBox(height: 20),
            
            // Overdue Rentals
            _buildSectionTitle("Overdue Rentals"),
            _buildOverdueSection(),
            
            const SizedBox(height: 20),
            
            // Maintenance Records
            _buildSectionTitle("Equipment in Maintenance"),
            _buildMaintenanceSection(),
            
            const SizedBox(height: 20),
            
            // Insights Section
            _buildSectionTitle("Insights & Recommendations"),
            _buildInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Total Equipment",
            totalEquipment.toString(),
            Icons.inventory,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            "Total Rentals",
            totalReservations.toString(),
            Icons.shopping_cart,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentStats() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _buildStatRow("Total Equipment", totalEquipment, Colors.blue),
            const Divider(),
            _buildStatRow("Available", availableEquipment, Colors.green),
            _buildStatRow("Rented Out", rentedEquipment, Colors.orange),
            _buildStatRow("In Maintenance", maintenanceEquipment, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationStats() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _buildStatRow("Total Reservations", totalReservations, Colors.blue),
            const Divider(),
            _buildStatRow("Pending", pendingReservations, Colors.orange),
            _buildStatRow("Approved", approvedReservations, Colors.green),
            _buildStatRow("Rejected", rejectedReservations, Colors.red),
            _buildStatRow("Overdue", overdueRentals, Colors.deepOrange),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationStats() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _buildStatRow("Total Donations", totalDonations, Colors.blue),
            const Divider(),
            _buildStatRow("Pending Review", pendingDonations, Colors.orange),
            _buildStatRow("Approved", approvedDonations, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostRentedList() {
    if (mostRentedEquipment.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text("No rental data available yet"),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mostRentedEquipment.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = mostRentedEquipment[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            title: Text(item["name"]),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "${item["count"]} rentals",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMostDonatedList() {
    if (mostDonatedTypes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text("No donation data available yet"),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mostDonatedTypes.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = mostDonatedTypes[index];
          return ListTile(
            leading: const Icon(Icons.volunteer_activism, color: Colors.green),
            title: Text(item["type"]),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "${item["count"]} donations",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverdueSection() {
    if (overdueList.isEmpty) {
      return Card(
        color: Colors.green.shade50,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  "No overdue rentals! All equipment is on track.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.red.shade50,
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red, size: 30),
                const SizedBox(width: 10),
                Text(
                  "${overdueList.length} Overdue Rental${overdueList.length > 1 ? 's' : ''}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: overdueList.length > 5 ? 5 : overdueList.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final item = overdueList[index];
              return ListTile(
                leading: const Icon(Icons.access_time, color: Colors.red),
                title: Text(item["equipmentName"]),
                subtitle: Text(
                  "Due: ${item["endDate"].toString().split(' ')[0]}",
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    "${item["daysOverdue"]} days overdue",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    if (maintenanceRecords.isEmpty) {
      return Card(
        color: Colors.green.shade50,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  "No equipment in maintenance. All equipment is operational!",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: maintenanceRecords.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = maintenanceRecords[index];
          return ListTile(
            leading: const Icon(Icons.build, color: Colors.orange),
            title: Text(item["equipmentName"]),
            subtitle: Text(item["equipmentType"]),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          );
        },
      ),
    );
  }

  Widget _buildInsights() {
    List<Map<String, dynamic>> insights = [];

    // Generate insights
    if (overdueRentals > 0) {
      insights.add({
        "icon": Icons.warning,
        "color": Colors.red,
        "title": "Overdue Attention Needed",
        "message": "$overdueRentals rental${overdueRentals > 1 ? 's are' : ' is'} overdue. Consider sending follow-up reminders.",
      });
    }

    if (pendingReservations > 5) {
      insights.add({
        "icon": Icons.pending_actions,
        "color": Colors.orange,
        "title": "Pending Reservations",
        "message": "You have $pendingReservations pending reservations awaiting approval.",
      });
    }

    if (availableEquipment < totalEquipment * 0.3) {
      insights.add({
        "icon": Icons.inventory_2,
        "color": Colors.blue,
        "title": "Low Inventory",
        "message": "Only $availableEquipment equipment items available. Consider accepting more donations.",
      });
    }

    if (mostRentedEquipment.isNotEmpty) {
      final topItem = mostRentedEquipment.first;
      insights.add({
        "icon": Icons.trending_up,
        "color": Colors.green,
        "title": "High Demand Equipment",
        "message": "${topItem['name']} is the most rented item (${topItem['count']} rentals). Ensure adequate stock.",
      });
    }

    if (maintenanceEquipment > 0) {
      insights.add({
        "icon": Icons.build_circle,
        "color": Colors.orange,
        "title": "Maintenance Items",
        "message": "$maintenanceEquipment equipment item${maintenanceEquipment > 1 ? 's are' : ' is'} in maintenance. Monitor completion status.",
      });
    }

    if (insights.isEmpty) {
      insights.add({
        "icon": Icons.check_circle,
        "color": Colors.green,
        "title": "All Good!",
        "message": "Your care center is running smoothly with no immediate issues.",
      });
    }

    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: insights.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, index) {
          final insight = insights[index];
          return ListTile(
            leading: Icon(
              insight["icon"],
              color: insight["color"],
              size: 30,
            ),
            title: Text(
              insight["title"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(insight["message"]),
          );
        },
      ),
    );
  }
}