import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../../trips/models/trip_model.dart';
import '../../trips/services/trip_service.dart';
import '../models/itinerary_activity_model.dart';
import '../services/itinerary_service.dart';

class ItineraryScreen extends StatefulWidget {
  final String? tripId;

  const ItineraryScreen({super.key, this.tripId});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final TripService _tripService = TripService();
  final ItineraryService _itineraryService = ItineraryService();
  final AuthService _authService = AuthService();

  late Future<TripModel?> _tripFuture;

  @override
  void initState() {
    super.initState();
    final tripId = widget.tripId;
    _tripFuture = tripId == null
        ? Future.value(null)
        : _tripService.getTrip(tripId);
  }

  Future<void> _openActivityForm({
    required TripModel trip,
    required List<_ItineraryDay> days,
    ItineraryActivity? activity,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _ActivityFormDialog(
          tripId: trip.id,
          days: days,
          activity: activity,
          service: _itineraryService,
        );
      },
    );

    if (saved == true) {
      _showMessage(
        activity == null ? 'Activity added.' : 'Activity updated.',
      );
    }
  }

  Future<void> _deleteActivity({
    required TripModel trip,
    required ItineraryActivity activity,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete activity?'),
          content: Text('Delete "${activity.title}" from the itinerary?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _itineraryService.deleteActivity(
        tripId: trip.id,
        activityId: activity.id,
      );
      _showMessage('Activity deleted.');
    } on ItineraryServiceException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to delete this activity.');
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
  Widget build(BuildContext context) {
    return FutureBuilder<TripModel?>(
      future: _tripFuture,
      builder: (context, tripSnapshot) {
        final trip = tripSnapshot.data;
        final currentUserId = _authService.currentFirebaseUser?.uid;
        final isAdmin =
            trip != null &&
            currentUserId != null &&
            trip.adminIds.contains(currentUserId);
        final days = trip == null ? const <_ItineraryDay>[] : _daysForTrip(trip);

        return Scaffold(
          backgroundColor: const Color(0xFFF4F8FC),
          body: Column(
            children: [
              _ItineraryHeader(
                showAddButton: isAdmin && trip != null,
                onAdd: trip == null
                    ? null
                    : () => _openActivityForm(trip: trip, days: days),
              ),
              if (tripSnapshot.connectionState == ConnectionState.waiting)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (trip == null)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Trip not found.',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: StreamBuilder<List<ItineraryActivity>>(
                    stream: _itineraryService.watchTripActivities(trip.id),
                    builder: (context, activitySnapshot) {
                      final activities =
                          activitySnapshot.data ??
                          const <ItineraryActivity>[];

                      if (activitySnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final daysWithActivities = days.where((day) {
                        return activities.any(
                          (activity) => activity.dayIndex == day.dayIndex,
                        );
                      }).toList();

                      if (daysWithActivities.isEmpty) {
                        return _EmptyItineraryState(
                          isAdmin: isAdmin,
                          onAdd: isAdmin
                              ? () => _openActivityForm(
                                  trip: trip,
                                  days: days,
                                )
                              : null,
                        );
                      }

                      return ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          20,
                        ),
                        children: [
                          ...daysWithActivities.map((day) {
                            final dayActivities = activities
                                .where(
                                  (activity) =>
                                      activity.dayIndex == day.dayIndex,
                                )
                                .toList();

                            return _DayCard(
                              day: day,
                              activities: dayActivities,
                              isAdmin: isAdmin,
                              onEdit: (activity) => _openActivityForm(
                                trip: trip,
                                days: days,
                                activity: activity,
                              ),
                              onDelete: (activity) => _deleteActivity(
                                trip: trip,
                                activity: activity,
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static List<_ItineraryDay> _daysForTrip(TripModel trip) {
    final start = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final end = DateTime(
      trip.endDate.year,
      trip.endDate.month,
      trip.endDate.day,
    );
    final dayCount = end.difference(start).inDays + 1;
    final safeDayCount = dayCount <= 0 ? 1 : dayCount;

    return List.generate(safeDayCount, (index) {
      final date = start.add(Duration(days: index));
      return _ItineraryDay(
        dayIndex: index,
        label: 'Day ${index + 1}',
        date: date,
      );
    });
  }
}

class _ItineraryHeader extends StatelessWidget {
  final bool showAddButton;
  final VoidCallback? onAdd;

  const _ItineraryHeader({
    required this.showAddButton,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 60,
        left: 20,
        right: 20,
        bottom: 25,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Trip Itinerary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (showAddButton)
                _HeaderAddButton(
                  onTap: onAdd,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              'Day-by-day travel schedule',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAddButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _HeaderAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add activity',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              Icons.add_rounded,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyItineraryState extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback? onAdd;

  const _EmptyItineraryState({
    required this.isAdmin,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 220,
              height: 170,
              child: CustomPaint(
                painter: _EmptyItineraryPainter(),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No itinerary yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Start adding plans to build the day-by-day schedule.'
                  : 'The trip itinerary will appear here once an admin adds activities.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onAdd,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Add first activity',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyItineraryPainter extends CustomPainter {
  const _EmptyItineraryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final lightBlue = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.fill;
    final midBlue = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width * .5, size.height * .45);
    canvas.drawCircle(center, size.width * .27, lightBlue);
    canvas.drawCircle(center, size.width * .2, blue);

    final planePath = Path()
      ..moveTo(size.width * .18, size.height * .28)
      ..lineTo(size.width * .77, size.height * .13)
      ..lineTo(size.width * .62, size.height * .32)
      ..lineTo(size.width * .50, size.height * .29)
      ..lineTo(size.width * .42, size.height * .46)
      ..lineTo(size.width * .35, size.height * .49)
      ..lineTo(size.width * .37, size.height * .31)
      ..close();
    canvas.drawPath(planePath, white);
    canvas.drawPath(planePath, blue);

    final pinPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * .68, size.height * .52),
          radius: 12,
        ),
      )
      ..moveTo(size.width * .68, size.height * .69)
      ..lineTo(size.width * .58, size.height * .55)
      ..lineTo(size.width * .78, size.height * .55)
      ..close();
    canvas.drawPath(pinPath, midBlue);
    canvas.drawCircle(
      Offset(size.width * .68, size.height * .52),
      4.5,
      white,
    );

    final suitcase = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .25,
        size.height * .62,
        size.width * .26,
        size.height * .24,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(suitcase, white);
    canvas.drawRRect(suitcase, blue);
    canvas.drawLine(
      Offset(size.width * .33, size.height * .62),
      Offset(size.width * .33, size.height * .56),
      blue,
    );
    canvas.drawLine(
      Offset(size.width * .43, size.height * .62),
      Offset(size.width * .43, size.height * .56),
      blue,
    );
    canvas.drawLine(
      Offset(size.width * .33, size.height * .56),
      Offset(size.width * .43, size.height * .56),
      blue,
    );

    final dashed = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 6; index++) {
      final x = size.width * (.18 + index * .1);
      canvas.drawLine(
        Offset(x, size.height * .92),
        Offset(x + 10, size.height * .92),
        dashed,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DayCard extends StatelessWidget {
  final _ItineraryDay day;
  final List<ItineraryActivity> activities;
  final bool isAdmin;
  final ValueChanged<ItineraryActivity> onEdit;
  final ValueChanged<ItineraryActivity> onDelete;

  const _DayCard({
    required this.day,
    required this.activities,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 15),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.label,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      _formatDate(day.date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${activities.length} activities',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (isAdmin && activities.length == 1) ...[
                  const SizedBox(width: 8),
                  _HeaderIconButton(
                    icon: Icons.edit_outlined,
                    onTap: () => onEdit(activities.first),
                  ),
                  const SizedBox(width: 6),
                  _HeaderIconButton(
                    icon: Icons.delete_outline,
                    onTap: () => onDelete(activities.first),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: activities.map((activity) {
                return _ActivityTile(
                  activity: activity,
                  showActions: isAdmin && activities.length > 1,
                  onEdit: () => onEdit(activity),
                  onDelete: () => onDelete(activity),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ItineraryActivity activity;
  final bool showActions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActivityTile({
    required this.activity,
    required this.showActions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 6),
              ],
            ),
            child: Icon(
              _iconFor(activity.iconKey),
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (activity.time != null &&
                          activity.time!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            activity.time!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      if (showActions) ...[
                        const SizedBox(width: 6),
                        _ActivityActionButton(
                          icon: Icons.edit_outlined,
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 4),
                        _ActivityActionButton(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFDC2626),
                          onTap: onDelete,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 15,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
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

class _ActivityActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActivityActionButton({
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF2563EB),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _ActivityFormDialog extends StatefulWidget {
  final String tripId;
  final List<_ItineraryDay> days;
  final ItineraryActivity? activity;
  final ItineraryService service;

  const _ActivityFormDialog({
    required this.tripId,
    required this.days,
    required this.service,
    this.activity,
  });

  @override
  State<_ActivityFormDialog> createState() => _ActivityFormDialogState();
}

class _ActivityFormDialogState extends State<_ActivityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _timeController;
  late final TextEditingController _locationController;
  late int _selectedDayIndex;
  String? _selectedIconKey;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    _selectedDayIndex = activity?.dayIndex ?? 0;
    _selectedIconKey = activity?.iconKey;
    _titleController = TextEditingController(text: activity?.title ?? '');
    _timeController = TextEditingController(text: activity?.time ?? '');
    _locationController = TextEditingController(
      text: activity?.location ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final activity = widget.activity;
      if (activity == null) {
        await widget.service.addActivity(
          tripId: widget.tripId,
          dayIndex: _selectedDayIndex,
          title: _titleController.text,
          time: _timeController.text,
          location: _locationController.text,
          iconKey: _selectedIconKey,
        );
      } else {
        await widget.service.updateActivity(
          tripId: widget.tripId,
          activityId: activity.id,
          dayIndex: _selectedDayIndex,
          title: _titleController.text,
          time: _timeController.text,
          location: _locationController.text,
          iconKey: _selectedIconKey,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ItineraryServiceException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to save this activity.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _timeFromText(_timeController.text) ?? TimeOfDay.now(),
    );

    if (pickedTime == null) {
      return;
    }

    final formattedTime = pickedTime.format(context);
    setState(() {
      _timeController.text = formattedTime;
    });
  }

  void _clearTime() {
    setState(() {
      _timeController.clear();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.activity == null
                          ? 'Add New Activity'
                          : 'Edit Activity',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _FieldLabel('Day'),
                DropdownButtonFormField<int>(
                  value: _selectedDayIndex,
                  items: widget.days.map((day) {
                    return DropdownMenuItem<int>(
                      value: day.dayIndex,
                      child: Text('${day.label} - ${_formatDate(day.date)}'),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedDayIndex = value;
                            });
                          }
                        },
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 12),
                _FieldLabel('Activity Name'),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    hintText: 'e.g. Sunset surf lesson',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                _FieldLabel('Time'),
                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: _isSaving ? null : _pickTime,
                  decoration: _inputDecoration(
                    hintText: 'Optional',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_timeController.text.isNotEmpty)
                          IconButton(
                            onPressed: _isSaving ? null : _clearTime,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        IconButton(
                          onPressed: _isSaving ? null : _pickTime,
                          icon: const Icon(Icons.schedule_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _FieldLabel('Location'),
                TextFormField(
                  controller: _locationController,
                  decoration: _inputDecoration(hintText: 'e.g. Kuta Beach'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                _FieldLabel('Icon'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('None'),
                      selected: _selectedIconKey == null,
                      onSelected: _isSaving
                          ? null
                          : (_) {
                              setState(() {
                                _selectedIconKey = null;
                              });
                            },
                      selectedColor: const Color(0xFFE0F2FE),
                      labelStyle: TextStyle(
                        color: _selectedIconKey == null
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ..._activityIcons.map((item) {
                      final isSelected = item.key == _selectedIconKey;
                      return InkWell(
                        onTap: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _selectedIconKey = item.key;
                                });
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE0F2FE)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            item.icon,
                            size: 19,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF111827),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(
                      widget.activity == null
                          ? 'Add to Itinerary'
                          : 'Save Activity',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static TimeOfDay? _timeFromText(String text) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s?(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (match == null) {
      return null;
    }

    final hourValue = int.tryParse(match.group(1) ?? '');
    final minuteValue = int.tryParse(match.group(2) ?? '');
    final meridiem = match.group(3)?.toUpperCase();
    if (hourValue == null ||
        minuteValue == null ||
        hourValue < 1 ||
        hourValue > 12 ||
        minuteValue < 0 ||
        minuteValue > 59 ||
        meridiem == null) {
      return null;
    }

    final hour = meridiem == 'PM'
        ? (hourValue == 12 ? 12 : hourValue + 12)
        : (hourValue == 12 ? 0 : hourValue);
    return TimeOfDay(hour: hour, minute: minuteValue);
  }

  static String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  static InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ItineraryDay {
  final int dayIndex;
  final String label;
  final DateTime date;

  const _ItineraryDay({
    required this.dayIndex,
    required this.label,
    required this.date,
  });
}

class _ActivityIconItem {
  final String key;
  final IconData icon;

  const _ActivityIconItem(this.key, this.icon);
}

const List<_ActivityIconItem> _activityIcons = [
  _ActivityIconItem('flight', Icons.flight),
  _ActivityIconItem('hotel', Icons.hotel),
  _ActivityIconItem('beach', Icons.beach_access),
  _ActivityIconItem('restaurant', Icons.restaurant),
  _ActivityIconItem('hiking', Icons.terrain),
  _ActivityIconItem('spa', Icons.hot_tub),
  _ActivityIconItem('coffee', Icons.coffee),
  _ActivityIconItem('museum', Icons.museum),
  _ActivityIconItem('temple', Icons.temple_buddhist),
  _ActivityIconItem('shopping', Icons.shopping_bag),
  _ActivityIconItem('music', Icons.music_note),
  _ActivityIconItem('car', Icons.directions_car),
  _ActivityIconItem('taxi', Icons.local_taxi),
  _ActivityIconItem('bus', Icons.directions_bus),
  _ActivityIconItem('train', Icons.train),
  _ActivityIconItem('boat', Icons.directions_boat),
  _ActivityIconItem('photo', Icons.photo_camera),
  _ActivityIconItem('map', Icons.map),
  _ActivityIconItem('celebration', Icons.celebration),
  _ActivityIconItem('sports', Icons.sports_soccer),
  _ActivityIconItem('scuba', Icons.scuba_diving),
  _ActivityIconItem('park', Icons.park),
  _ActivityIconItem('nightlife', Icons.nightlife),
  _ActivityIconItem('local_activity', Icons.local_activity),
];

IconData _iconFor(String? key) {
  return _activityIcons
      .firstWhere(
        (item) => item.key == key,
        orElse: () => const _ActivityIconItem('event', Icons.event_note),
      )
      .icon;
}

String _formatDate(DateTime date) {
  return '${_monthName(date.month)} ${date.day}, ${date.year}';
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
