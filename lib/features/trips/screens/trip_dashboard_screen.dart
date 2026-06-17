import 'package:flutter/material.dart';


import '../../../core/routes/app_routes.dart';

import '../models/trip_model.dart';
import '../services/trip_service.dart';

class TripDashboardScreen extends StatefulWidget {
  final String? tripId;

  const TripDashboardScreen({super.key, this.tripId});

  @override
  State<TripDashboardScreen> createState() => _TripDashboardScreenState();
}

class _TripDashboardScreenState extends State<TripDashboardScreen> {
  final TripService _tripService = TripService();
  late final Future<TripModel?> _tripFuture;

  @override
  void initState() {
    super.initState();
    final tripId = widget.tripId;
    _tripFuture = tripId == null
        ? Future.value(null)
        : _tripService.getTrip(tripId);
  }

  @override
  Widget build(BuildContext context) {
    final expenses = [
      {
        "title": "Flight Tickets",
        "subtitle": "Paid by Sarah - May 5",
        "amount": "\$1200",
      },
      {
        "title": "Hotel Deposit",
        "subtitle": "Paid by Mike - May 3",
        "amount": "\$800",
      },
      {
        "title": "Car Rental",
        "subtitle": "Paid by You - May 1",
        "amount": "\$340",
      },
    ];

    final tasks = [
      {"title": "Book scuba diving tour", "subtitle": "Sarah - Due May 10"},
      {"title": "Get travel insurance", "subtitle": "You - Due May 12"},
      {"title": "Confirm hotel check-in", "subtitle": "Mike - Due May 15"},
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
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 14),
              FutureBuilder<TripModel?>(
                future: _tripFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 320,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return _tripCard(context, snapshot.data);
                },
              ),
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
                children: [
                  ActionCard(
                    icon: Icons.calendar_today_outlined,
                    title: "Itinerary",
                    iconColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFDBEAFE),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.itinerary,
                      );
                    },
                  ),

                  const ActionCard(
                    icon: Icons.attach_money,
                    title: "Budget",
                    iconColor: Color(0xFF16A34A),
                    backgroundColor: Color(0xFFDCFCE7),
                  ),

                  ActionCard(
                    icon: Icons.task_alt,
                    title: "Tasks",
                    iconColor: const Color(0xFFA855F7),
                    backgroundColor: const Color(0xFFF3E8FF),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.tasks,
                      );
                    },
                  ),

                  const ActionCard(
                    icon: Icons.camera_alt,
                    title: "Photos",
                    iconColor: Color(0xFFEC4899),
                    backgroundColor: Color(0xFFFCE7F3),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Expenses",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                      context,
                      AppRoutes.addExpenses,
                    );
                    },
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
                        (expense) => ListTile(
                          title: Text(expense["title"]!),
                          subtitle: Text(expense["subtitle"]!),
                          trailing: Text(
                            expense["amount"]!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pending Tasks",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  Text("3 tasks", style: TextStyle(color: Color(0xFF6B7280))),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Alerts",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _tripCard(BuildContext context, TripModel? trip) {
    final title = trip?.name ?? "Bali Adventure";
    final subtitle = trip?.description?.isNotEmpty == true
        ? trip!.description!
        : "Plan, budget, and share memories together";
    final dateRange = trip == null
        ? "June 15 - June 25, 2026"
        : "${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}";
    final daysLeft = trip == null
        ? "38 days left"
        : _daysLeftLabel(trip.startDate);
    final coverImageUrl =
        trip?.coverImageUrl ??
        "https://images.unsplash.com/photo-1537996194471-e657df975ab4";

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
                  coverImageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      color: const Color(0xFF1D4ED8),
                      child: const Icon(
                        Icons.travel_explore,
                        color: Colors.white,
                        size: 48,
                      ),
                    );
                  },
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
                    colors: [Colors.transparent, Colors.black.withOpacity(.65)],
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
                    onPressed: () => Navigator.pop(context),
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
                      Navigator.pushNamed(
                      context,
                      AppRoutes.inviteMembers,
                    );
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
                      Navigator.pushNamed(
                        context,
                        AppRoutes.tripSettings,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 40,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                    const Icon(Icons.calendar_month, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateRange,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        daysLeft,
                        style: const TextStyle(
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
                      child: _SummaryTile(
                        title: "Budget Used",
                        value: "\$0",
                        backgroundColor: const Color(0xFFF1F5F9),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: const LinearProgressIndicator(
                            value: 0,
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: _SummaryTile(
                        title: "Pending Tasks",
                        value: "0",
                        subtitle: "tasks to complete",
                        backgroundColor: Color(0xFFEAF7F7),
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

  String _formatDate(DateTime date) {
    return "${_monthName(date.month)} ${date.day}, ${date.year}";
  }

  String _daysLeftLabel(DateTime startDate) {
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final tripDate = DateTime(startDate.year, startDate.month, startDate.day);
    final difference = tripDate.difference(currentDate).inDays;

    if (difference > 1) {
      return "$difference days left";
    }
    if (difference == 1) {
      return "1 day left";
    }
    if (difference == 0) {
      return "Starts today";
    }
    return "In progress";
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return months[month - 1];
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color backgroundColor;
  final Widget? child;

  const _SummaryTile({
    required this.title,
    required this.value,
    this.subtitle,
    required this.backgroundColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 135,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            child ??
                Text(
                  subtitle ?? "",
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
          ],
        ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.backgroundColor,
    this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
