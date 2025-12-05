// lib/screens/renter/enhanced_renter_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_theme.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/info_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/slide_in_animation.dart';
import '../../services/notification_service.dart';
import '../../auth/login_screen.dart';
import 'renter_equipment_list.dart';
import '../reservations/renter_reservations_page.dart';
import '../donations/donation_page.dart';
import '../tracking/rental_tracking_page.dart';
import '../tracking/notifications_page.dart';
import '../profile/profile_page.dart';

class RenterHome extends StatefulWidget {
  const RenterHome({super.key});

  @override
  State<RenterHome> createState() => _EnhancedRenterHomeState();
}

class _EnhancedRenterHomeState extends State<RenterHome> {
  final notificationService = NotificationService();
  String renterName = "User";
  int myReservations = 0;
  int activeRentals = 0;
  int unreadNotifications = 0;

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
        renterName = userDoc.data()?["name"] ?? "User";
      });
    }

    // Load statistics
    final reservationsSnapshot = await FirebaseFirestore.instance
        .collection("reservations")
        .where("userId", isEqualTo: uid)
        .get();

    final activeSnapshot = await FirebaseFirestore.instance
        .collection("reservations")
        .where("userId", isEqualTo: uid)
        .where("status", isEqualTo: "approved")
        .get();

    if (mounted) {
      setState(() {
        myReservations = reservationsSnapshot.docs.length;
        activeRentals = activeSnapshot.docs.length;
      });
    }
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const EnhancedLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.successColor.withOpacity(0.05),
              Colors.white,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
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
                                    "Hello,",
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    renterName,
                                    style: AppTheme.headingLarge.copyWith(
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Notification Bell
                                StreamBuilder<int>(
                                  stream: notificationService.getUnreadCount(uid),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data ?? 0;
                                    return Stack(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const NotificationsPage(),
                                              ),
                                            );
                                          },
                                          icon: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.notifications_outlined,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                        if (count > 0)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: AppTheme.errorColor,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 18,
                                                minHeight: 18,
                                              ),
                                              child: Text(
                                                count > 9 ? '9+' : '$count',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => logout(context),
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.errorColor.withOpacity(0.1),
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Statistics Cards
                      SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            SlideInAnimation(
                              delay: 100,
                              child: SizedBox(
                                width: 160,
                                child: InfoCard(
                                  title: "Total",
                                  value: myReservations.toString(),
                                  icon: Icons.history,
                                  color: AppTheme.infoColor,
                                  subtitle: "reservations",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RenterReservationsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SlideInAnimation(
                              delay: 200,
                              child: SizedBox(
                                width: 160,
                                child: InfoCard(
                                  title: "Active",
                                  value: activeRentals.toString(),
                                  icon: Icons.check_circle,
                                  color: AppTheme.successColor,
                                  subtitle: "rentals",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RentalTrackingPage(
                                            isAdmin: false),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Section Header
                      SlideInAnimation(
                        delay: 300,
                        child: const SectionHeader(
                          title: "Quick Actions",
                          subtitle: "Rent, donate, and track equipment",
                          icon: Icons.apps,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dashboard Grid
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
                      icon: Icons.medical_services_outlined,
                      label: "Browse Equipment",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RenterEquipmentList(),
                          ),
                        );
                      },
                      color: AppTheme.infoColor,
                      delay: 50,
                    ),
                    DashboardCard(
                      icon: Icons.history,
                      label: "Reservations",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RenterReservationsPage(),
                          ),
                        );
                      },
                      color: AppTheme.warningColor,
                      delay: 100,
                    ),
                    DashboardCard(
                      icon: Icons.track_changes,
                      label: "Tracking",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const RentalTrackingPage(isAdmin: false),
                          ),
                        );
                      },
                      color: AppTheme.successColor,
                      delay: 150,
                    ),
                    DashboardCard(
                      icon: Icons.volunteer_activism,
                      label: "Donate Items",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DonationPage(),
                          ),
                        );
                      },
                      color: AppTheme.secondaryColor,
                      delay: 200,
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
                      delay: 250,
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