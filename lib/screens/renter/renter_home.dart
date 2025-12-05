import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/login_screen.dart';
import 'renter_equipment_list.dart';
import '../reservations/renter_reservations_page.dart';
import '../donations/donation_page.dart';
import '../tracking/rental_tracking_page.dart';
import '../tracking/notifications_page.dart';
import '../profile/profile_page.dart';
import '../../services/notification_service.dart';

class RenterHome extends StatelessWidget {
  const RenterHome({super.key});

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Renter Dashboard"),
        centerTitle: true,
        actions: [
          // Notification bell with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                },
              ),
              StreamBuilder<int>(
                stream: notificationService.getUnreadCount(uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == 0) {
                    return const SizedBox();
                  }

                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${snapshot.data}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
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
              icon: Icons.medical_services_outlined,
              label: "Browse Equipment",
              page: RenterEquipmentList(),
            ),
            _dashboardButton(
              context,
              icon: Icons.history,
              label: "My Reservations",
              page: const RenterReservationsPage(),
            ),
            _dashboardButton(
              context,
              icon: Icons.track_changes,
              label: "Rental Tracking",
              page: const RentalTrackingPage(isAdmin: false),
            ),
            _dashboardButton(
              context,
              icon: Icons.volunteer_activism,
              label: "Donate Items",
              page: const DonationPage(),
            ),
            _dashboardButton(
              context,
              icon: Icons.notifications_active,
              label: "Notifications",
              page: const NotificationsPage(),
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
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: Colors.green),
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