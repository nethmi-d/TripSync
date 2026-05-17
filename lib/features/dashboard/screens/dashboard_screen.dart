import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _goTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardItems = [
      _DashboardItem(
        title: 'My Trips',
        icon: Icons.card_travel,
        route: AppRoutes.myTrips,
      ),
      _DashboardItem(
        title: 'Budget',
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.budgetExpenses,
      ),
      _DashboardItem(
        title: 'Debts',
        icon: Icons.receipt_long_outlined,
        route: AppRoutes.personalDebt,
      ),
      _DashboardItem(
        title: 'Itinerary',
        icon: Icons.calendar_month_outlined,
        route: AppRoutes.itinerary,
      ),
      _DashboardItem(
        title: 'Places',
        icon: Icons.place_outlined,
        route: AppRoutes.savedPlaces,
      ),
      _DashboardItem(
        title: 'Accommodation',
        icon: Icons.hotel_outlined,
        route: AppRoutes.accommodation,
      ),
      _DashboardItem(
        title: 'Gallery',
        icon: Icons.photo_library_outlined,
        route: AppRoutes.imageGallery,
      ),
      _DashboardItem(
        title: 'Notifications',
        icon: Icons.notifications_outlined,
        route: AppRoutes.notifications,
      ),
      _DashboardItem(
        title: 'Profile',
        icon: Icons.person_outline,
        route: AppRoutes.profile,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TripSync Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFECFEFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dashboardItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final item = dashboardItems[index];

            return InkWell(
              onTap: () => _goTo(context, item.route),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 42, color: const Color(0xFF3B82F6)),
                    const SizedBox(height: 14),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final String route;

  const _DashboardItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}
