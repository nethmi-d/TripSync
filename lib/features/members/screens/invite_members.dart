import 'package:flutter/material.dart';

import '../../auth/models/user_model.dart';
import '../../auth/services/user_service.dart';
import '../../trips/models/trip_model.dart';
import '../../trips/services/trip_service.dart';
import '../models/trip_invite_model.dart';
import '../services/trip_invite_service.dart';

class InviteMembersScreen extends StatefulWidget {
  final String? tripId;

  const InviteMembersScreen({super.key, this.tripId});

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  final TextEditingController _emailController = TextEditingController();
  final ScrollController _searchResultsScrollController = ScrollController();
  final TripService _tripService = TripService();
  final TripInviteService _inviteService = TripInviteService();
  final UserService _userService = UserService();

  TripModel? _trip;
  AppUser? _searchedUser;
  List<AppUser> _searchResults = const [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    final tripId = widget.tripId;
    if (tripId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final trip = await _tripService.getTrip(tripId);
      if (!mounted) {
        return;
      }

      if (trip == null) {
        _showMessage('Trip not found.');
        Navigator.pop(context);
        return;
      }

      setState(() {
        _trip = trip;
        _isLoading = false;
      });
    } on TripServiceException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to load this trip.');
      Navigator.pop(context);
    }
  }

  Future<void> _sendInvite() async {
    final trip = _trip;
    if (trip == null) {
      _showMessage('Trip not found.');
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter a user email address.');
      return;
    }
    if (_searchedUser == null || _searchedUser!.email != email) {
      await _searchUser();
      if (_searchedUser == null) {
        return;
      }
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _inviteService.sendInvite(trip: trip, targetEmail: email);
      if (!mounted) {
        return;
      }
      _emailController.clear();
      _showMessage('Join request sent to $email');
    } on TripInviteException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to send the join request.');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _searchUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _searchedUser = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final user = await _userService.getUserByEmail(email);
      if (!mounted) {
        return;
      }

      setState(() {
        _searchedUser = user;
        _searchResults = user == null ? const [] : [user];
      });

      if (user == null) {
        _showMessage('No user found with that email.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to search for that user.');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _searchUsersByQuery(String query) async {
    final trip = _trip;
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchedUser = null;
        _searchResults = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final users = await _userService.searchUsersByEmailPrefix(
        normalizedQuery,
      );
      if (!mounted) {
        return;
      }

      final filteredUsers = users.where((user) {
        if (trip == null) {
          return true;
        }
        return !trip.memberIds.contains(user.uid);
      }).toList();

      setState(() {
        _searchResults = filteredUsers;
        if (_searchedUser != null &&
            filteredUsers.every((user) => user.uid != _searchedUser!.uid)) {
          _searchedUser = null;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchResults = const [];
        _searchedUser = null;
      });
      _showMessage(
        'Unable to search that user. Check Firestore user search rules.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectUser(AppUser user) {
    setState(() {
      _searchedUser = user;
      _emailController.text = user.email;
      _searchResults = const [];
    });
  }

  Future<void> _cancelInvite(TripInvite invite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel request'),
          content: Text(
            'Cancel the join request sent to ${invite.targetEmail}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _inviteService.cancelInvite(invite.id);
      _showMessage('Request cancelled.');
    } catch (_) {
      _showMessage('Unable to cancel that request.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _searchResultsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invite Members',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : trip == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _inviteCard(),
                  const SizedBox(height: 18),
                  StreamBuilder<List<TripInvite>>(
                    stream: _inviteService.watchTripInvitesForTrip(trip.id),
                    builder: (context, snapshot) {
                      final invites = snapshot.data ?? const <TripInvite>[];
                      return _requestsCard(invites);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _inviteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE8F1FF),
                child: Icon(Icons.person_add_alt_1, color: Color(0xFF2563EB)),
              ),
              SizedBox(width: 10),
              Text(
                'Invite Members',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Search users by email and send a join request',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              if (_searchedUser != null &&
                  _searchedUser!.email != value.trim()) {
                setState(() {
                  _searchedUser = null;
                });
              }
              _searchUsersByQuery(value);
            },
            decoration: InputDecoration(
              hintText: 'Search by email',
              prefixIcon: const Icon(Icons.email_outlined),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Scrollbar(
                  controller: _searchResultsScrollController,
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _searchResultsScrollController,
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 68),
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        onTap: () => _selectUser(user),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8F1FF),
                          backgroundImage:
                              user.photoUrl != null && user.photoUrl!.isNotEmpty
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null || user.photoUrl!.isEmpty
                              ? Text(
                                  _nameInitials(
                                    user.displayName.isNotEmpty
                                        ? user.displayName
                                        : user.fullName,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName
                              : user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          if (_searchedUser != null) ...[
            const SizedBox(height: 14),
            _searchedUserCard(_searchedUser!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSending || _searchedUser == null
                  ? null
                  : _sendInvite,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                  ),
                ),
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : const Text(
                          'Request to Join',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchedUserCard(AppUser user) {
    final displayName = user.displayName.isNotEmpty
        ? user.displayName
        : user.fullName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE8F1FF),
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null || user.photoUrl!.isEmpty
                ? Text(
                    _nameInitials(displayName),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E)),
        ],
      ),
    );
  }

  Widget _requestsCard(List<TripInvite> invites) {
    final pendingCount = invites
        .where((invite) => invite.status == TripInviteStatus.pending)
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Requests',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F1FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    pendingCount.toString(),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (invites.isEmpty)
            const Text(
              'No requests yet.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          else
            ...invites.map(_requestTile),
        ],
      ),
    );
  }

  Widget _requestTile(TripInvite invite) {
    final status = invite.status;
    final statusLabel = switch (status) {
      TripInviteStatus.pending => 'Pending',
      TripInviteStatus.accepted => 'Accepted',
      TripInviteStatus.rejected => 'Rejected',
      TripInviteStatus.cancelled => 'Cancelled',
    };
    final statusBackground = switch (status) {
      TripInviteStatus.pending => const Color(0xFFDBEAFE),
      TripInviteStatus.accepted => const Color(0xFFDCFCE7),
      TripInviteStatus.rejected => const Color(0xFFFEE2E2),
      TripInviteStatus.cancelled => const Color(0xFFF3F4F6),
    };
    final statusTextColor = switch (status) {
      TripInviteStatus.pending => const Color(0xFF2563EB),
      TripInviteStatus.accepted => const Color(0xFF16A34A),
      TripInviteStatus.rejected => const Color(0xFFDC2626),
      TripInviteStatus.cancelled => const Color(0xFF374151),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1D9BF0),
                child: Text(
                  _emailInitial(invite.targetEmail),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.targetEmail.split('@').first,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      invite.targetEmail,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      _timeAgo(invite.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(invite.requestedRole)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: statusTextColor),
                    ),
                  ),
                ),
              ),
              if (status == TripInviteStatus.pending) ...[
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: () => _cancelInvite(invite),
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _emailInitial(String email) {
    final name = email.split('@').first;
    if (name.isEmpty) {
      return '?';
    }
    return name.substring(0, 1).toUpperCase();
  }

  static String _nameInitials(String name) {
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
