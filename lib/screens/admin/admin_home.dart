import 'package:care_center_app/screens/tracking/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/login_screen.dart';
import 'admin_equipment_list.dart';
import '../reservations/admin_reservations_page.dart';
import '../donations/admin_donations_page.dart';
import '../tracking/rental_tracking_page.dart';
import '../profile/profile_page.dart';
import '../reports/reports_page.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          children: [
            _dashboardButton(
              context,
              icon: Icons.person,
              label: "Manage Profile",
              page: ProfilePage(),
            ),
            _dashboardButton(
              context,
              icon: Icons.inventory_2,
              label: "Manage Equipment",
              page: AdminEquipmentList(),
            ),
            _dashboardButton(
              context,
              icon: Icons.pending_actions,
              label: "Reservations",
              page: const AdminReservationsPage(),
            ),
            _dashboardButton(
              context,
              icon: Icons.track_changes,
              label: "Rental Tracking",
              page: const RentalTrackingPage(isAdmin: true),
            ),
              _dashboardButton(
              context,
              icon: Icons.notifications_active,
              label: "Notifications",
              page: const NotificationsPage(),
            ),
            _dashboardButton(
              context,
              icon: Icons.volunteer_activism,
              label: "Donations",
              page: AdminDonationsPage(),
            ),
            _dashboardButton(
              context,
              icon: Icons.analytics,
              label: "Reports",
              page: const ReportsPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget page,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}