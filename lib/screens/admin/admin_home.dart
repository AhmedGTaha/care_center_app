import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_theme.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/slide_in_animation.dart';
import '../../auth/login_screen.dart';
import 'admin_equipment_list.dart';
import '../reservations/admin_reservations_page.dart';
import '../donations/admin_donations_page.dart';
import '../tracking/rental_tracking_page.dart';
import '../tracking/notifications_page.dart';
import '../profile/profile_page.dart';
import '../reports/reports_page.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _EnhancedAdminHomeState();
}

class _EnhancedAdminHomeState extends State<AdminHome> {
  String adminName = "Admin";
  int totalEquipment = 0;
  int pendingReservations = 0;
  int pendingDonations = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (userDoc.exists) {
      setState(() {
        adminName = userDoc.data()?["name"] ?? "Admin";
      });
    }

    final equipmentSnapshot =
        await FirebaseFirestore.instance.collection("equipment").get();
    final reservationsSnapshot = await FirebaseFirestore.instance
        .collection("reservations")
        .where("status", isEqualTo: "pending")
        .get();
    final donationsSnapshot = await FirebaseFirestore.instance
        .collection("donations")
        .where("status", isEqualTo: "pending")
        .get();

    if (mounted) {
      setState(() {
        totalEquipment = equipmentSnapshot.docs.length;
        pendingReservations = reservationsSnapshot.docs.length;
        pendingDonations = donationsSnapshot.docs.length;
      });
    }
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              Colors.white,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SlideInAnimation(
                        delay: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome back,",
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    adminName,
                                    style: AppTheme.headingLarge.copyWith(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => logout(context),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.logout,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      SlideInAnimation(
                        delay: 400,
                        child: const SectionHeader(
                          title: "Quick Actions",
                          subtitle: "Manage your care center",
                          icon: Icons.dashboard,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildListDelegate([
                    DashboardCard(
                      icon: Icons.person,
                      label: "Profile",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                      },
                      color: AppTheme.primaryColor,
                      delay: 0,
                    ),
                    DashboardCard(
                      icon: Icons.inventory_2,
                      label: "Equipment",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminEquipmentList(),
                          ),
                        );
                      },
                      color: AppTheme.infoColor,
                      delay: 50,
                    ),
                    DashboardCard(
                      icon: Icons.pending_actions,
                      label: "Reservations",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminReservationsPage(),
                          ),
                        );
                      },
                      color: AppTheme.warningColor,
                      delay: 100,
                      showBadge: pendingReservations > 0,
                      badgeText: pendingReservations.toString(),
                    ),
                    DashboardCard(
                      icon: Icons.track_changes,
                      label: "Tracking",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const RentalTrackingPage(isAdmin: true),
                          ),
                        );
                      },
                      color: AppTheme.successColor,
                      delay: 150,
                    ),
                    DashboardCard(
                      icon: Icons.notifications_active,
                      label: "Notifications",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsPage(),
                          ),
                        );
                      },
                      color: AppTheme.accentColor,
                      delay: 200,
                    ),
                    DashboardCard(
                      icon: Icons.volunteer_activism,
                      label: "Donations",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminDonationsPage(),
                          ),
                        );
                      },
                      color: AppTheme.successColor,
                      delay: 250,
                      showBadge: pendingDonations > 0,
                      badgeText: pendingDonations.toString(),
                    ),
                    DashboardCard(
                      icon: Icons.analytics,
                      label: "Reports",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsPage(),
                          ),
                        );
                      },
                      color: AppTheme.primaryColor,
                      delay: 300,
                    ),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}