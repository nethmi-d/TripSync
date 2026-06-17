import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/models/user_model.dart';
import '../../auth/services/user_service.dart';
import '../models/trip_model.dart';
import '../services/trip_cover_service.dart';
import '../services/trip_service.dart';

class TripSettingsScreen extends StatefulWidget {
  final String? tripId;

  const TripSettingsScreen({super.key, this.tripId});

  @override
  State<TripSettingsScreen> createState() => _TripSettingsScreenState();
}

class _TripSettingsScreenState extends State<TripSettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TripService _tripService = TripService();
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  TripModel? _trip;
  List<_TripMemberViewData> _members = const [];
  final Set<String> _busyMemberIds = <String>{};
  DateTime? _startDate;
  DateTime? _endDate;
  XFile? _selectedCoverImage;
  bool _isLoading = true;
  bool _isSaving = false;

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

      _tripNameController.text = trip.name;
      _descriptionController.text = trip.description ?? '';

      setState(() {
        _trip = trip;
        _startDate = trip.startDate;
        _endDate = trip.endDate;
        _isLoading = false;
      });

      await _loadMembers(trip);
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
      _showMessage('Unable to load trip settings.');
      Navigator.pop(context);
    }
  }

  Future<void> _loadMembers(TripModel trip) async {
    final currentUid = _auth.currentUser?.uid;
    final members = await Future.wait(
      trip.memberIds.map((uid) async {
        AppUser? user;
        try {
          user = await _userService.getUser(uid);
        } catch (_) {
          user = null;
        }

        final isCurrentUser = uid == currentUid;
        final displayName = isCurrentUser
            ? 'You'
            : _resolveMemberName(user, fallbackUid: uid);

        return _TripMemberViewData(
          uid: uid,
          name: displayName,
          email: user?.email ?? '',
          role: trip.adminIds.contains(uid) ? 'Admin' : 'Member',
          canRemove: uid != trip.createdBy,
          initials: _memberInitials(
            isCurrentUser
                ? (user?.displayName ?? user?.fullName ?? 'You')
                : _resolveMemberName(user, fallbackUid: uid),
          ),
        );
      }),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _members = members;
    });
  }

  Future<void> _updateMemberRole(
    _TripMemberViewData member,
    String role,
  ) async {
    final trip = _trip;
    if (trip == null) {
      return;
    }

    setState(() {
      _busyMemberIds.add(member.uid);
    });

    try {
      final updatedTrip = await _tripService.updateMemberRole(
        tripId: trip.id,
        memberUid: member.uid,
        isAdmin: role == 'Admin',
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _trip = updatedTrip;
      });
      await _loadMembers(updatedTrip);
      _showMessage('${member.name} updated to $role.');
    } on TripServiceException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to update that member role.');
    } finally {
      if (mounted) {
        setState(() {
          _busyMemberIds.remove(member.uid);
        });
      }
    }
  }

  Future<void> _removeMember(_TripMemberViewData member) async {
    final trip = _trip;
    if (trip == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove member'),
          content: Text('Remove ${member.name} from this trip?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _busyMemberIds.add(member.uid);
    });

    try {
      final updatedTrip = await _tripService.removeMember(
        tripId: trip.id,
        memberUid: member.uid,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _trip = updatedTrip;
      });
      await _loadMembers(updatedTrip);
      _showMessage('${member.name} removed from the trip.');
    } on TripServiceException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to remove that member.');
    } finally {
      if (mounted) {
        setState(() {
          _busyMemberIds.remove(member.uid);
        });
      }
    }
  }

  String _resolveMemberName(AppUser? user, {required String fallbackUid}) {
    final displayName = user?.displayName.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final fullName = user?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final email = user?.email.trim() ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return fallbackUid.substring(0, fallbackUid.length.clamp(0, 6));
  }

  String _memberInitials(String name) {
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

  Future<void> _pickCoverImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1000,
        imageQuality: 84,
      );

      if (image == null) {
        return;
      }

      final size = await image.length();
      if (size > TripCoverService.maximumCoverBytes) {
        _showMessage('Choose a cover image smaller than 5 MB.');
        return;
      }

      setState(() {
        _selectedCoverImage = image;
      });
    } catch (_) {
      _showMessage('Unable to select that image. Please try another one.');
    }
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (date == null) {
      return;
    }

    setState(() {
      _startDate = date;
      if (_endDate != null && _endDate!.isBefore(date)) {
        _endDate = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (date == null) {
      return;
    }

    setState(() {
      _endDate = date;
    });
  }

  Future<void> _saveTripDetails() async {
    final tripId = widget.tripId;
    if (tripId == null) {
      _showMessage('Trip ID is missing.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showMessage('Select both start and end dates.');
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showMessage('End date cannot be before start date.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final coverBytes = await _selectedCoverImage?.readAsBytes();
      final updatedTrip = await _tripService.updateTripDetails(
        tripId: tripId,
        name: _tripNameController.text,
        description: _descriptionController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        coverBytes: coverBytes,
        coverFilename: _selectedCoverImage?.name,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _trip = updatedTrip;
        _selectedCoverImage = null;
      });
      _showMessage('Trip details updated.');
      Navigator.pop(context, updatedTrip);
    } on TripServiceException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to update the trip. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'mm/dd/yyyy';
    }

    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trip Settings',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    children: [
                      _tripDetailsCard(),
                      const SizedBox(height: 16),
                      _membersCard(),
                      const SizedBox(height: 16),
                      _dangerZone(),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveTripDetails,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                  ),
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tripDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Trip Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _coverImageSection(),
          const SizedBox(height: 20),
          const Text(
            'Trip Name',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tripNameController,
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) {
                return 'Trip name is required.';
              }
              if (name.length < 2) {
                return 'Trip name must contain at least 2 characters.';
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell your group about this trip...',
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _dateField(
                  label: 'Start Date',
                  value: _formatDate(_startDate),
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateField(
                  label: 'End Date',
                  value: _formatDate(_endDate),
                  onTap: _pickEndDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coverImageSection() {
    final currentUrl = _trip?.coverImageUrl;
    final selectedImage = _selectedCoverImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cover Image',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: selectedImage != null
                    ? FutureBuilder<Uint8List>(
                        future: selectedImage.readAsBytes(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const ColoredBox(
                              color: Color(0xFFF1F5F9),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : currentUrl != null && currentUrl.isNotEmpty
                    ? Image.network(
                        currentUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _coverFallback(),
                      )
                    : _coverFallback(),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF2563EB)),
                  onPressed: _isSaving ? null : _pickCoverImage,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _coverFallback() {
    return Container(
      color: const Color(0xFF1D4ED8),
      child: const Center(
        child: Icon(Icons.travel_explore, color: Colors.white, size: 48),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isSaving ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _membersCard() {
    final memberCount = _members.length;

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              const Icon(Icons.group_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Text(
                'Members',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '$memberCount members',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._members.map(_memberTile),
        ],
      ),
    );
  }

  Widget _memberTile(_TripMemberViewData member) {
    final isAdmin = member.role == 'Admin';
    final isBusy = _busyMemberIds.contains(member.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
                  member.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (member.email.isNotEmpty)
                      Text(
                        member.email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (isBusy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else if (member.canRemove)
                IconButton(
                  onPressed: () => _removeMember(member),
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color(0xFFF3E8FF)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: member.role,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'Member',
                          child: Text('Member'),
                        ),
                        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      ],
                      onChanged: member.uid == _trip?.createdBy || isBusy
                          ? null
                          : (value) {
                              if (value == null || value == member.role) {
                                return;
                              }
                              _updateMemberRole(member, value);
                            },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Deleting this trip will permanently remove all data including expenses, settlements, itinerary and images.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Trip'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripMemberViewData {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool canRemove;
  final String initials;

  const _TripMemberViewData({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.canRemove,
    required this.initials,
  });
}
