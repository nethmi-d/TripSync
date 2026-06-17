import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../trips/models/trip_model.dart';
import '../../trips/services/trip_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TripService _tripService = TripService();
  final AuthService _authService = AuthService();
  Future<AppUser?> _profileFuture = Future.value(null);

  @override
  void initState() {
    super.initState();
    _profileFuture = _authService.getCurrentUserProfile();
  }

  void _openTripDashboard(BuildContext context, String tripId) {
    Navigator.pushNamed(context, AppRoutes.tripDashboard, arguments: tripId);
  }

  void _openCreateTrip(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.createTrip);
  }

  void _openNotifications(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.notifications);
  }

  void _openProfile(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.profile).then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profileFuture = _authService.getCurrentUserProfile();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TripModel>>(
      stream: _tripService.watchCurrentUserTrips(),
      builder: (context, snapshot) {
        final trips = snapshot.data ?? const <TripModel>[];
        final recentTrips = trips.take(3).toList();
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

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
                  tripCount: trips.length,
                  profileFuture: _profileFuture,
                  onNotificationsTap: () => _openNotifications(context),
                  onProfileTap: () => _openProfile(context),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : trips.isEmpty
                      ? _DashboardEmptyState(
                          onCreateTap: () => _openCreateTrip(context),
                        )
                      : SingleChildScrollView(
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
                                    onTap: () =>
                                        _openTripDashboard(context, trip.id),
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
                              if (trips.isEmpty)
                                const SizedBox.shrink()
                              else
                                GridView.builder(
                                  itemCount: trips.length,
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
                                    final trip = trips[index];

                                    return _SmallTripCard(
                                      trip: trip,
                                      onTap: () =>
                                          _openTripDashboard(context, trip.id),
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
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final int tripCount;
  final Future<AppUser?> profileFuture;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  const _DashboardHeader({
    required this.tripCount,
    required this.profileFuture,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final tripLabel = tripCount == 1
        ? '1 trip planned'
        : '$tripCount trips planned';

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Trips',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tripLabel,
                  style: const TextStyle(
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
            icon: FutureBuilder<AppUser?>(
              future: profileFuture,
              builder: (context, snapshot) {
                final user = snapshot.data;
                final photoUrl = user?.photoUrl;
                final displayName = user?.displayName ?? user?.fullName ?? '';

                return CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFE5E7EB),
                  backgroundImage: photoUrl == null || photoUrl.isEmpty
                      ? null
                      : NetworkImage(photoUrl),
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Text(
                          _profileInitials(displayName),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _profileInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

class _RecentTripCard extends StatelessWidget {
  final TripModel trip;
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
            SizedBox(
              height: 118,
              width: double.infinity,
              child: _TripCover(
                imageUrl: trip.coverImageUrl,
                borderRadius: BorderRadius.zero,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      trip.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
                    text: _dateRange(trip),
                  ),
                  const SizedBox(height: 8),
                  _TripMetaRow(
                    icon: Icons.group_outlined,
                    text: _memberCountLabel(trip.memberIds.length),
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

class _SmallTripCard extends StatelessWidget {
  final TripModel trip;
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
              child: SizedBox(
                width: double.infinity,
                child: _TripCover(
                  imageUrl: trip.coverImageUrl,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
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
                        '${trip.memberIds.length}',
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

class _TripCover extends StatelessWidget {
  final String? imageUrl;
  final BorderRadius borderRadius;
  final Widget? child;

  const _TripCover({
    required this.imageUrl,
    required this.borderRadius,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url == null || url.isEmpty)
            _CoverFallback()
          else
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _CoverFallback(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.58),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.travel_explore, color: Colors.white70, size: 36),
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _DashboardEmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 90),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const _TravelEmptyIllustration(),
                const SizedBox(height: 18),
                const Text(
                  'No trips yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Plan your first trip group, invite your people, and keep everything in one place.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCreateTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Plan a Trip',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF0284C7),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add dates, a cover photo, and members later. Start with the trip name first.',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelEmptyIllustration extends StatelessWidget {
  const _TravelEmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 18,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFDCEEFF), Color(0xFFEEF7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 78,
            child: _LeafShape(
              height: 82,
              width: 36,
              color: const Color(0xFFC7D9FF),
              rotation: -0.28,
            ),
          ),
          Positioned(
            right: 22,
            top: 70,
            child: _LeafShape(
              height: 88,
              width: 40,
              color: const Color(0xFFD6D8FF),
              rotation: 0.32,
            ),
          ),
          Positioned(
            top: 38,
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF8FB3FF), width: 3),
              ),
              child: CustomPaint(painter: _GlobeLinePainter()),
            ),
          ),
          const Positioned(
            top: 28,
            right: 54,
            child: Icon(
              Icons.flight_rounded,
              color: Color(0xFF1D4ED8),
              size: 34,
            ),
          ),
          const Positioned(top: 64, left: 78, child: _PinBadge()),
          const Positioned(top: 118, right: 84, child: _PinBadge()),
          Positioned(
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _TravelerFigure(
                  shirtColor: Color(0xFFFB923C),
                  pantsColor: Color(0xFF1E3A8A),
                  bagColor: Color(0xFF93C5FD),
                  facingRight: true,
                ),
                SizedBox(width: 14),
                _LuggageStack(),
                SizedBox(width: 14),
                _TravelerFigure(
                  shirtColor: Color(0xFF2563EB),
                  pantsColor: Color(0xFF0F172A),
                  bagColor: Color(0xFFFCA5A5),
                  facingRight: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelerFigure extends StatelessWidget {
  final Color shirtColor;
  final Color pantsColor;
  final Color bagColor;
  final bool facingRight;

  const _TravelerFigure({
    required this.shirtColor,
    required this.pantsColor,
    required this.bagColor,
    required this.facingRight,
  });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFFF8C7A6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 36,
          decoration: BoxDecoration(
            color: shirtColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 32,
              decoration: BoxDecoration(
                color: pantsColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 32,
              decoration: BoxDecoration(
                color: pantsColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ],
    );

    return SizedBox(
      width: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: facingRight
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: body,
          ),
          Positioned(
            top: 30,
            left: facingRight ? 34 : null,
            right: facingRight ? null : 34,
            child: Container(
              width: 16,
              height: 20,
              decoration: BoxDecoration(
                color: bagColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuggageStack extends StatelessWidget {
  const _LuggageStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 82,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 4,
            left: 0,
            child: Container(
              width: 34,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 38,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF64748B),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Container(
              width: 36,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF97316),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 9,
                    right: 9,
                    top: -12,
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF94A3B8),
                          width: 2.4,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 17,
                    top: 8,
                    bottom: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFFFE7D1)),
                      child: SizedBox(width: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeafShape extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double rotation;

  const _LeafShape({
    required this.width,
    required this.height,
    required this.color,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(width),
            topRight: Radius.circular(width),
            bottomLeft: Radius.circular(width / 2),
            bottomRight: Radius.circular(width / 2),
          ),
        ),
      ),
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFFFB7185),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.place_rounded, color: Colors.white, size: 14),
    );
  }
}

class _GlobeLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8FB3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final dashPaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawArc(
      Rect.fromLTWH(14, 34, size.width - 28, size.height - 68),
      0.2,
      2.7,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(30, 12, size.width - 60, size.height - 24),
      1.55,
      3.1,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(10, 54, size.width - 20, size.height - 92),
      3.45,
      2.1,
      false,
      dashPaint,
    );

    final path = Path()
      ..moveTo(34, 74)
      ..quadraticBezierTo(62, 38, 92, 66)
      ..quadraticBezierTo(110, 84, 118, 54);
    canvas.drawPath(path, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

String _dateRange(TripModel trip) {
  return '${_formatShortDate(trip.startDate)} - ${_formatShortDate(trip.endDate)}';
}

String _formatShortDate(DateTime date) {
  return '${_monthName(date.month)} ${date.day}';
}

String _memberCountLabel(int count) {
  return count == 1 ? '1 member' : '$count members';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}
