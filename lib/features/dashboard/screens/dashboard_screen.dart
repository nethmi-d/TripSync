import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _openTripDashboard(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.tripDashboard);
  }

  void _openCreateTrip(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.createTrip);
  }

  void _openNotifications(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.notifications);
  }

  void _openProfile(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final recentTrips = [
      const _TripData(
        title: 'Bali Adventure 2026',
        location: 'Bali, Indonesia',
        dates: 'Jun 15 - Jun 25, 2026',
        members: '8 members',
        colors: [Color(0xFF0F766E), Color(0xFF111827)],
      ),
      const _TripData(
        title: 'Euro Trip',
        location: 'Paris, France',
        dates: 'Jul 10 - Jul 30, 2026',
        members: '5 members',
        colors: [Color(0xFF4338CA), Color(0xFF111827)],
      ),
    ];

    final allTrips = [
      const _TripData(
        title: 'Bali Adventure 2026',
        location: 'Bali',
        dates: 'Jun 15 - Jun 25',
        members: '8',
        colors: [Color(0xFF0F766E), Color(0xFF111827)],
      ),
      const _TripData(
        title: 'Euro Trip',
        location: 'Europe',
        dates: 'Jul 10 - Jul 30',
        members: '5',
        colors: [Color(0xFF4338CA), Color(0xFF111827)],
      ),
      const _TripData(
        title: 'Island Escape',
        location: 'Thailand',
        dates: 'Aug 02 - Aug 09',
        members: '4',
        colors: [Color(0xFF0284C7), Color(0xFF111827)],
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F7FB),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateTrip(context),
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _DashboardHeader(
              onNotificationsTap: () => _openNotifications(context),
              onProfileTap: () => _openProfile(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Trips',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...recentTrips.map(
                      (trip) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RecentTripCard(
                          trip: trip,
                          onTap: () => _openTripDashboard(context),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'All Trips',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.builder(
                      itemCount: allTrips.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.88,
                          ),
                      itemBuilder: (context, index) {
                        final trip = allTrips[index];

                        return _SmallTripCard(
                          trip: trip,
                          onTap: () => _openTripDashboard(context),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  const _DashboardHeader({
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Trips',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '3 trips planned',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: onNotificationsTap,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onProfileTap,
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _RecentTripCard extends StatelessWidget {
  final _TripData trip;
  final VoidCallback onTap;

  const _RecentTripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 118,
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: trip.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  trip.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  _TripMetaRow(
                    icon: Icons.calendar_today_outlined,
                    text: trip.dates,
                  ),
                  const SizedBox(height: 8),
                  _TripMetaRow(icon: Icons.group_outlined, text: trip.members),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallTripCard extends StatelessWidget {
  final _TripData trip;
  final VoidCallback onTap;

  const _SmallTripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.10),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: trip.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        size: 13,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trip.members,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TripMetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TripData {
  final String title;
  final String location;
  final String dates;
  final String members;
  final List<Color> colors;

  const _TripData({
    required this.title,
    required this.location,
    required this.dates,
    required this.members,
    required this.colors,
  });
}

// comment
