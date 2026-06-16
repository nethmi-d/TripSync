import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/app_logger.dart';
import '../models/trip_model.dart';
import 'trip_cover_service.dart';

class TripService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final TripCoverService _coverService;

  TripService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    TripCoverService? coverService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _coverService = coverService ?? TripCoverService();

  CollectionReference<Map<String, dynamic>> get _trips =>
      _firestore.collection(FirestoreCollections.trips);

  Future<TripModel> createTrip({
    required String name,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    Uint8List? coverBytes,
    String? coverFilename,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const TripServiceException(
        'Please sign in before creating a trip.',
      );
    }

    try {
      final doc = _trips.doc();
      String? coverUrl;
      String? coverPublicId;

      if (coverBytes != null && coverFilename != null) {
        final idToken = await user.getIdToken();
        if (idToken == null) {
          throw const TripServiceException(
            'Unable to authenticate trip cover upload.',
          );
        }

        final upload = await _coverService.uploadTripCover(
          idToken: idToken,
          tripId: doc.id,
          bytes: coverBytes,
          filename: coverFilename,
        );
        coverUrl = upload.url;
        coverPublicId = upload.publicId;
        AppLogger.info(
          'TripService',
          'Trip cover uploaded for ${doc.id}: $coverPublicId',
        );
      }

      final now = DateTime.now().toUtc();
      final trip = TripModel(
        id: doc.id,
        name: name.trim(),
        description: _nullableTrimmed(description),
        startDate: startDate,
        endDate: endDate,
        createdBy: user.uid,
        memberIds: [user.uid],
        coverImageUrl: coverUrl,
        coverImagePublicId: coverPublicId,
        createdAt: now,
        updatedAt: now,
      );

      AppLogger.info('TripService', 'Creating trip ${doc.id}.');
      await doc.set({
        ...trip.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('TripService', 'Trip ${doc.id} saved to Firestore.');
      return trip;
    } on TripCoverException catch (error) {
      throw TripServiceException(error.message);
    } on FirebaseException catch (error) {
      AppLogger.error('TripService.createTrip.firebase.${error.code}', error);
      if (error.code == 'permission-denied') {
        throw const TripServiceException(
          'Trip photo uploaded, but Firestore rejected saving the trip. Add the trips security rule and try again.',
        );
      }
      throw TripServiceException(
        error.message ?? 'Unable to save the trip. Please try again.',
      );
    } catch (error, stackTrace) {
      AppLogger.error('TripService.createTrip', error, stackTrace: stackTrace);
      if (error is TripServiceException) {
        rethrow;
      }
      throw const TripServiceException(
        'Unable to create the trip. Please try again.',
      );
    }
  }

  Future<TripModel?> getTrip(String tripId) async {
    final snapshot = await _trips.doc(tripId).get();
    final data = snapshot.data();

    return data == null ? null : TripModel.fromMap(data);
  }

  Stream<List<TripModel>> watchCurrentUserTrips() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const []);
    }

    return _trips.where('memberIds', arrayContains: user.uid).snapshots().map((
      snapshot,
    ) {
      final trips =
          snapshot.docs.map((doc) => TripModel.fromMap(doc.data())).toList()
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

      return trips;
    });
  }

  static String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class TripServiceException implements Exception {
  final String message;

  const TripServiceException(this.message);
}
