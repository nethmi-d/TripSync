import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/app_logger.dart';
import '../models/itinerary_activity_model.dart';

class ItineraryService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ItineraryService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _activities(String tripId) {
    return _firestore
        .collection(FirestoreCollections.trips)
        .doc(tripId)
        .collection(FirestoreCollections.itinerary);
  }

  Stream<List<ItineraryActivity>> watchTripActivities(String tripId) {
    return _activities(tripId).snapshots().map((snapshot) {
      final activities =
          snapshot.docs
              .map((doc) => ItineraryActivity.fromMap(doc.data()))
              .toList()
            ..sort(_sortActivities);
      return activities;
    });
  }

  Future<void> addActivity({
    required String tripId,
    required int dayIndex,
    required String title,
    required String? time,
    required String location,
    required String? iconKey,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ItineraryServiceException('Please sign in first.');
    }

    try {
      await _logTripAccessState(
        scope: 'ItineraryService.addActivity',
        tripId: tripId,
        userId: user.uid,
      );
      final doc = _activities(tripId).doc();
      final now = DateTime.now().toUtc();
      final activity = ItineraryActivity(
        id: doc.id,
        tripId: tripId,
        dayIndex: dayIndex,
        title: title.trim(),
        time: _cleanOptionalText(time),
        location: location.trim(),
        iconKey: iconKey,
        createdAt: now,
        updatedAt: now,
      );

      await doc.set({
        ...activity.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'ItineraryService.addActivity',
        error,
        stackTrace: stackTrace,
      );
      if (error.code == 'permission-denied') {
        throw const ItineraryServiceException(
          'Firestore rules blocked adding this activity.',
        );
      }
      throw ItineraryServiceException(
        error.message ?? 'Unable to add this activity.',
      );
    }
  }

  Future<void> updateActivity({
    required String tripId,
    required String activityId,
    required int dayIndex,
    required String title,
    required String? time,
    required String location,
    required String? iconKey,
  }) async {
    try {
      final user = _auth.currentUser;
      await _logTripAccessState(
        scope: 'ItineraryService.updateActivity',
        tripId: tripId,
        userId: user?.uid,
      );
      await _activities(tripId).doc(activityId).update({
        'dayIndex': dayIndex,
        'title': title.trim(),
        'time': _cleanOptionalText(time),
        'location': location.trim(),
        'iconKey': iconKey,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'ItineraryService.updateActivity',
        error,
        stackTrace: stackTrace,
      );
      if (error.code == 'permission-denied') {
        throw const ItineraryServiceException(
          'Firestore rules blocked updating this activity.',
        );
      }
      throw ItineraryServiceException(
        error.message ?? 'Unable to update this activity.',
      );
    }
  }

  Future<void> deleteActivity({
    required String tripId,
    required String activityId,
  }) async {
    try {
      final user = _auth.currentUser;
      await _logTripAccessState(
        scope: 'ItineraryService.deleteActivity',
        tripId: tripId,
        userId: user?.uid,
      );
      await _activities(tripId).doc(activityId).delete();
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'ItineraryService.deleteActivity',
        error,
        stackTrace: stackTrace,
      );
      if (error.code == 'permission-denied') {
        throw const ItineraryServiceException(
          'Firestore rules blocked deleting this activity.',
        );
      }
      throw ItineraryServiceException(
        error.message ?? 'Unable to delete this activity.',
      );
    }
  }

  static int _sortActivities(
    ItineraryActivity left,
    ItineraryActivity right,
  ) {
    final dayCompare = left.dayIndex.compareTo(right.dayIndex);
    if (dayCompare != 0) {
      return dayCompare;
    }

    final leftMinutes = _minutesFromTime(left.time);
    final rightMinutes = _minutesFromTime(right.time);
    if (leftMinutes != null && rightMinutes != null) {
      final timeCompare = leftMinutes.compareTo(rightMinutes);
      if (timeCompare != 0) {
        return timeCompare;
      }
    } else if (leftMinutes != null) {
      return -1;
    } else if (rightMinutes != null) {
      return 1;
    }

    return left.createdAt.compareTo(right.createdAt);
  }

  static String? _cleanOptionalText(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  static int? _minutesFromTime(String? value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s?(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value?.trim() ?? '');
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
    return hour * 60 + minuteValue;
  }

  Future<void> _logTripAccessState({
    required String scope,
    required String tripId,
    required String? userId,
  }) async {
    try {
      final tripSnapshot = await _firestore
          .collection(FirestoreCollections.trips)
          .doc(tripId)
          .get();
      final tripData = tripSnapshot.data();
      final adminIds = List<String>.from(tripData?['adminIds'] as List? ?? []);
      final memberIds = List<String>.from(
        tripData?['memberIds'] as List? ?? [],
      );

      AppLogger.info(
        scope,
        'tripId=$tripId userId=$userId '
        'isAdmin=${userId != null && adminIds.contains(userId)} '
        'isMember=${userId != null && memberIds.contains(userId)} '
        'adminIds=$adminIds memberIds=$memberIds',
      );
    } catch (error, stackTrace) {
      AppLogger.error('$scope.accessCheck', error, stackTrace: stackTrace);
    }
  }
}

class ItineraryServiceException implements Exception {
  final String message;

  const ItineraryServiceException(this.message);
}
