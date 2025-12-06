import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final db = FirebaseFirestore.instance;
  
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type, 
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
  
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return db
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .limit(50)
        .snapshots();
  }
  
  Stream<QuerySnapshot> getAdminNotifications() {
    return db
        .collection("notifications")
        .where("type", whereIn: ["donation", "maintenance"])
        .limit(50)
        .snapshots();
  }

  Future<void> markAsRead(String notificationId) async {
    await db.collection("notifications").doc(notificationId).update({
      "isRead": true,
    });
  }

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

  Stream<int> getUnreadCount(String userId) {
    return db
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .where("isRead", isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

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

      if (daysRemaining == 2) {
        await createNotification(
          userId: userId,
          title: "Return Reminder",
          message: "$equipmentName is due in 2 days",
          type: "rental_reminder",
          reservationId: doc.id,
        );
      }

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

  Future<void> notifyAdminAboutDonation(String donorName, String itemName) async {
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