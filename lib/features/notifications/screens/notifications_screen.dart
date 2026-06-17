import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../members/models/trip_invite_model.dart';
import '../../members/services/trip_invite_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TripInviteService _inviteService = TripInviteService();
  final AuthService _authService = AuthService();
  final Set<String> _busyInviteIds = <String>{};
  Future<AppUser?> _profileFuture = Future.value(null);

  @override
  void initState() {
    super.initState();
    _profileFuture = _authService.getCurrentUserProfile();
  }

  Future<void> _respondToInvite(TripInvite invite, bool accept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(accept ? 'Approve request' : 'Reject request'),
          content: Text(
            accept
                ? 'Join ${invite.tripName}?'
                : 'Reject the request to join ${invite.tripName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(accept ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _busyInviteIds.add(invite.id);
    });

    try {
      await _inviteService.respondToInvite(invite: invite, accept: accept);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'You joined ${invite.tripName}.' : 'Request rejected.',
            ),
          ),
        );
    } on TripInviteException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to update that invite.')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _busyInviteIds.remove(invite.id);
        });
      }
    }
  }

  void _openProfile() {
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
    return StreamBuilder<List<TripInvite>>(
      stream: _inviteService.watchCurrentUserInvites(),
      builder: (context, snapshot) {
        final invites = snapshot.data ?? const <TripInvite>[];
        final cards = invites.map(_NotificationCardData.fromInvite).toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
        final newCount = cards.where((card) => card.isNew).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F8FC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            centerTitle: false,
            title: const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              IconButton(
                onPressed: _openProfile,
                icon: FutureBuilder<AppUser?>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final photoUrl = user?.photoUrl;
                    final displayName =
                        user?.displayName ?? user?.fullName ?? '';

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
              Container(
                margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: newCount > 0 ? Colors.red : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '$newCount new',
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
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : cards.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final invite = card.invite;

                    return _NotificationCard(
                      card: card,
                      isBusy: invite == null
                          ? false
                          : _busyInviteIds.contains(invite.id),
                      onApprove: invite != null &&
                              invite.status == TripInviteStatus.pending
                          ? () => _respondToInvite(invite, true)
                          : null,
                      onReject: invite != null &&
                              invite.status == TripInviteStatus.pending
                          ? () => _respondToInvite(invite, false)
                          : null,
                    );
                  },
                ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationCardData card;
  final bool isBusy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _NotificationCard({
    required this.card,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: card.isNew
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
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: card.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(card.icon, color: card.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.message,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card.timeLabel,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (card.isNew)
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
            if (card.showActions) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: card.statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          card.statusText,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: card.statusTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (onReject != null && onApprove != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isBusy ? null : onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isBusy ? null : onApprove,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Approve'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCardData {
  final String title;
  final String message;
  final String timeLabel;
  final IconData icon;
  final Color color;
  final bool isNew;
  final bool showActions;
  final String statusText;
  final Color statusColor;
  final Color statusTextColor;
  final DateTime createdAt;
  final TripInvite? invite;

  const _NotificationCardData({
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.icon,
    required this.color,
    required this.isNew,
    required this.showActions,
    required this.statusText,
    required this.statusColor,
    required this.statusTextColor,
    required this.createdAt,
    required this.invite,
  });

  factory _NotificationCardData.fromInvite(TripInvite invite) {
    final isPending = invite.status == TripInviteStatus.pending;

    final statusText = switch (invite.status) {
      TripInviteStatus.pending => 'Pending',
      TripInviteStatus.accepted => 'Approved',
      TripInviteStatus.rejected => 'Rejected',
      TripInviteStatus.cancelled => 'Cancelled',
    };

    final statusColor = switch (invite.status) {
      TripInviteStatus.pending => const Color(0xFFDBEAFE),
      TripInviteStatus.accepted => const Color(0xFFDCFCE7),
      TripInviteStatus.rejected => const Color(0xFFFEE2E2),
      TripInviteStatus.cancelled => const Color(0xFFF3F4F6),
    };

    final statusTextColor = switch (invite.status) {
      TripInviteStatus.pending => const Color(0xFF2563EB),
      TripInviteStatus.accepted => const Color(0xFF16A34A),
      TripInviteStatus.rejected => const Color(0xFFDC2626),
      TripInviteStatus.cancelled => const Color(0xFF374151),
    };

    return _NotificationCardData(
      title: 'New Join Request',
      message:
          '${invite.senderName} wants you to join "${invite.tripName}"',
      timeLabel: _timeAgo(invite.createdAt),
      icon: Icons.person_add_alt_1,
      color: const Color(0xFF3B82F6),
      isNew: isPending,
      showActions: true,
      statusText: statusText,
      statusColor: statusColor,
      statusTextColor: statusTextColor,
      createdAt: invite.createdAt,
      invite: invite,
    );
  }

  static String _timeAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes <= 0 ? 1 : difference.inMinutes;
      return '$minutes minutes ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    }
    return '${difference.inDays} days ago';
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
