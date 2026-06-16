import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});

  final List<Map<String, dynamic>> notifications = [
    {
      "title": "New Join Request",
      "message": "Sarah Johnson wants to join \"Bali Adventure 2026\"",
      "time": "2 hours ago",
      "icon": Icons.person_add_alt_1,
      "color": Color(0xFF3B82F6),
      "isNew": true,
    },
    {
      "title": "Budget Alert",
      "message": "Bali Adventure 2026 has consumed 53% of budget",
      "time": "4 hours ago",
      "icon": Icons.warning_amber_rounded,
      "color": Color(0xFFF59E0B),
      "isNew": true,
    },
    {
      "title": "Payment Received",
      "message": "Mike Chen marked payment for group settlement",
      "time": "1 day ago",
      "icon": Icons.attach_money,
      "color": Color(0xFF22C55E),
      "isNew": false,
    },
    {
      "title": "Settlement Approved",
      "message":
          "Admin confirmed your payment for \"Bali Adventure 2026\"",
      "time": "1 day ago",
      "icon": Icons.check_circle_outline,
      "color": Color(0xFFA855F7),
      "isNew": false,
    },
    {
      "title": "Debt Approval Request",
      "message":
          "Emma Wilson needs your approval for \"Lunch at Warung\"",
      "time": "2 days ago",
      "icon": Icons.attach_money,
      "color": Color(0xFFEC4899),
      "isNew": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final newCount =
        notifications.where((item) => item["isNew"] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Container(
            margin: const EdgeInsets.only(
              right: 16,
              top: 12,
              bottom: 12,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                "$newCount new",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: notification["isNew"]
                    ? const Color(0xFFB9D5FF)
                    : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: notification["color"].withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      notification["icon"],
                      color: notification["color"],
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification["title"],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          notification["message"],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          notification["time"],
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (notification["isNew"])
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}