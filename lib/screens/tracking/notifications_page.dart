import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await notificationService.markAllAsRead(uid);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All notifications marked as read")),
              );
            },
            tooltip: "Mark all as read",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationService.getUserNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "No notifications yet",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (_, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data["title"] ?? "";
              final message = data["message"] ?? "";
              final type = data["type"] ?? "";
              final isRead = data["isRead"] ?? false;
              final createdAt = (data["createdAt"] as Timestamp).toDate();

              return Card(
                color: isRead ? Colors.white : Colors.blue.shade50,
                elevation: isRead ? 1 : 3,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: _getNotificationIcon(type, isRead),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(message),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!isRead) {
                      await notificationService.markAsRead(doc.id);
                    }
                  },
                  trailing: isRead
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getNotificationIcon(String type, bool isRead) {
    IconData icon;
    Color color;

    switch (type) {
      case "rental_reminder":
        icon = Icons.access_time;
        color = Colors.blue;
        break;
      case "overdue":
        icon = Icons.warning_amber;
        color = Colors.red;
        break;
      case "donation":
        icon = Icons.volunteer_activism;
        color = Colors.green;
        break;
      case "maintenance":
        icon = Icons.build;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    if (isRead) {
      color = color.withOpacity(0.5);
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";

    return "${dt.day}/${dt.month}/${dt.year}";
  }
}