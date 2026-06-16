import 'package:flutter/material.dart';

class TripDashboardScreen extends StatelessWidget {
  const TripDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = [
      {
        "title": "Flight Tickets",
        "subtitle": "Paid by Sarah • May 5",
        "amount": "\$1200",
      },
      {
        "title": "Hotel Deposit",
        "subtitle": "Paid by Mike • May 3",
        "amount": "\$800",
      },
      {
        "title": "Car Rental",
        "subtitle": "Paid by You • May 1",
        "amount": "\$340",
      },
    ];

    final tasks = [
      {
        "title": "Book scuba diving tour",
        "subtitle": "Sarah • Due May 10",
      },
      {
        "title": "Get travel insurance",
        "subtitle": "You • Due May 12",
      },
      {
        "title": "Confirm hotel check-in",
        "subtitle": "Mike • Due May 15",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Manage your adventures",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 14),

              _tripCard(context),

              const SizedBox(height: 24),

              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  ActionCard(
                    icon: Icons.calendar_today_outlined,
                    title: "Itinerary",
                    iconColor: Color(0xFF2563EB),
                    backgroundColor: Color(0xFFDBEAFE),
                  ),

                  ActionCard(
                    icon: Icons.attach_money,
                    title: "Budget",
                    iconColor: Color(0xFF16A34A),
                    backgroundColor: Color(0xFFDCFCE7),
                  ),

                  ActionCard(
                    icon: Icons.task_alt,
                    title: "Tasks",
                    iconColor: Color(0xFFA855F7),
                    backgroundColor: Color(0xFFF3E8FF),
                  ),

                  ActionCard(
                    icon: Icons.camera_alt,
                    title: "Photos",
                    iconColor: Color(0xFFEC4899),
                    backgroundColor: Color(0xFFFCE7F3),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Expenses",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "+ Add",
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: expenses
                      .map(
                        (e) => ListTile(
                          title: Text(e["title"]!),
                          subtitle: Text(e["subtitle"]!),
                          trailing: Text(
                            e["amount"]!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),

              const Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pending Tasks",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "3 tasks",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: tasks
                      .map(
                        (task) => CheckboxListTile(
                          value: false,
                          onChanged: (_) {},
                          title: Text(task["title"]!),
                          subtitle: Text(task["subtitle"]!),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Alerts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _tripCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Image.network(
                  "https://images.unsplash.com/photo-1537996194471-e657df975ab4",
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(.65),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 12,
                left: 12,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),

              Positioned(
                top: 12,
                right: 60,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(
                      Icons.group_add_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      // invite members
                    },
                  ),
                ),
              ),

              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      // trip settings
                    },
                  ),
                ),
              ),

              const Positioned(
                left: 18,
                bottom: 40,
                child: Text(
                  "Bali Adventure",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const Positioned(
                left: 18,
                bottom: 16,
                child: Text(
                  "Bali, Indonesia",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),

                    const Text(
                      "June 15 - June 25, 2026",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "38 days left",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 135,
                        child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Budget Used",
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              "\$2340",
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 12),

                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(20),
                              child:
                                  const LinearProgressIndicator(
                                value: 0.53,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: SizedBox(
                        height: 135,
                        child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7F7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pending Tasks",
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "3",
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "tasks to complete",
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color backgroundColor;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}