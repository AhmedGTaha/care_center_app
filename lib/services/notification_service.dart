import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final db = FirebaseFirestore.instance;

  // Create a notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'rental_reminder', 'overdue', 'donation', 'maintenance'
    String? reservationId,
    String? equipmentId,
  }) async {
    await db.collection("notifications").add({
      "userId": userId,
      "title": title,
      "message": message,
      "type": type,
      "reservationId": reservationId,
      "equipmentId": equipmentId,
      "isRead": false,
      "createdAt": Timestamp.now(),
    });
  }

  // Get user notifications
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return db
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .limit(50)
        .snapshots();
  }

  // Get admin notifications
  Stream<QuerySnapshot> getAdminNotifications() {
    return db
        .collection("notifications")
        .where("type", whereIn: ["donation", "maintenance"])
        .orderBy("createdAt", descending: true)
        .limit(50)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await db.collection("notifications").doc(notificationId).update({
      "isRead": true,
    });
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final notifications = await db
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .where("isRead", isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      await doc.reference.update({"isRead": true});
    }
  }

  // Get unread count
  Stream<int> getUnreadCount(String userId) {
    return db
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .where("isRead", isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Check for overdue rentals and send notifications
  Future<void> checkOverdueRentals() async {
    final now = DateTime.now();

    final reservations = await db
        .collection("reservations")
        .where("status", isEqualTo: "approved")
        .where("lifecycleStatus", whereIn: ["Reserved", "Checked Out"])
        .get();

    for (var doc in reservations.docs) {
      final data = doc.data();
      final endDate = (data["endDate"] as Timestamp).toDate();
      final userId = data["userId"];
      final equipmentName = data["equipmentName"];

      final daysRemaining = endDate.difference(now).inDays;

      // Notify 2 days before due
      if (daysRemaining == 2) {
        await createNotification(
          userId: userId,
          title: "Return Reminder",
          message: "$equipmentName is due in 2 days",
          type: "rental_reminder",
          reservationId: doc.id,
        );
      }

      // Notify if overdue
      if (daysRemaining < 0) {
        await createNotification(
          userId: userId,
          title: "Overdue Rental",
          message: "$equipmentName is overdue by ${daysRemaining.abs()} days",
          type: "overdue",
          reservationId: doc.id,
        );
      }
    }
  }

  // Notify admin about new donation
  Future<void> notifyAdminAboutDonation(String donorName, String itemName) async {
    // Get all admin users
    final admins = await db
        .collection("users")
        .where("role", isEqualTo: "admin")
        .get();

    for (var admin in admins.docs) {
      await createNotification(
        userId: admin.id,
        title: "New Donation",
        message: "$donorName has submitted $itemName for donation",
        type: "donation",
      );
    }
  }

  // Notify admin about equipment needing maintenance
  Future<void> notifyMaintenanceNeeded(String equipmentId, String equipmentName) async {
    final admins = await db
        .collection("users")
        .where("role", isEqualTo: "admin")
        .get();

    for (var admin in admins.docs) {
      await createNotification(
        userId: admin.id,
        title: "Maintenance Required",
        message: "$equipmentName requires maintenance",
        type: "maintenance",
        equipmentId: equipmentId,
      );
    }
  }
}