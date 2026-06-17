import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/user_service.dart';
import '../../trips/models/trip_model.dart';
import '../models/trip_invite_model.dart';

class TripInviteService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final UserService _userService;

  TripInviteService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    UserService? userService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _userService = userService ?? UserService(firestore: firestore);

  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection(FirestoreCollections.tripInvites);

  Future<void> sendInvite({
    required TripModel trip,
    required String targetEmail,
    String requestedRole = 'Member',
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw const TripInviteException(
          'Please sign in before sending invites.',
        );
      }

      final normalizedEmail = targetEmail.trim().toLowerCase();
      if (normalizedEmail.isEmpty) {
        throw const TripInviteException('Enter a user email address.');
      }

      final targetUser = await _userService.getUserByEmail(normalizedEmail);
      if (targetUser == null) {
        throw const TripInviteException('No user found with that email.');
      }
      if (targetUser.uid == currentUser.uid) {
        throw const TripInviteException('You are already in this trip.');
      }
      if (!trip.adminIds.contains(currentUser.uid)) {
        throw const TripInviteException('Only trip admins can send invites.');
      }
      if (trip.memberIds.contains(targetUser.uid)) {
        throw const TripInviteException('That user is already a trip member.');
      }

      final existingInviteSnapshot = await _invites
          .where('tripId', isEqualTo: trip.id)
          .where('targetUid', isEqualTo: targetUser.uid)
          .limit(10)
          .get();
      final hasPendingInvite = existingInviteSnapshot.docs.any(
        (doc) =>
            (doc.data()['status'] as String?) == TripInviteStatus.pending.name,
      );
      if (hasPendingInvite) {
        throw const TripInviteException(
          'A pending invite already exists for that user.',
        );
      }

      final senderProfile = await _userService.getUser(currentUser.uid);
      final senderName = _senderName(senderProfile, currentUser.email);

      final doc = _invites.doc();
      final now = DateTime.now().toUtc();
      final invite = TripInvite(
        id: doc.id,
        tripId: trip.id,
        tripName: trip.name,
        tripCoverImageUrl: trip.coverImageUrl,
        senderUid: currentUser.uid,
        senderName: senderName,
        senderEmail: currentUser.email ?? senderProfile?.email ?? '',
        targetUid: targetUser.uid,
        targetEmail: targetUser.email,
        requestedRole: requestedRole,
        status: TripInviteStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      await doc.set({
        ...invite.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info(
        'TripInviteService',
        'Invite ${doc.id} created for ${trip.id}.',
      );
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'TripInviteService.sendInvite',
        error,
        stackTrace: stackTrace,
      );
      if (error.code == 'permission-denied') {
        throw const TripInviteException(
          'Invite write was blocked by Firestore rules.',
        );
      }
      if (error.code == 'failed-precondition') {
        throw const TripInviteException(
          'Firestore index is missing for invites.',
        );
      }
      throw TripInviteException(error.message ?? 'Unable to send invite.');
    }
  }

  Stream<List<TripInvite>> watchTripInvitesForTrip(String tripId) {
    return _invites
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
          final invites =
              snapshot.docs
                  .map((doc) => TripInvite.fromMap(doc.data()))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return invites;
        });
  }

  Stream<List<TripInvite>> watchCurrentUserInvites() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(const []);
    }

    return _invites
        .where('targetUid', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          final invites =
              snapshot.docs
                  .map((doc) => TripInvite.fromMap(doc.data()))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return invites;
        });
  }

  Future<void> cancelInvite(String inviteId) async {
    await _invites.doc(inviteId).update({
      'status': TripInviteStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> respondToInvite({
    required TripInvite invite,
    required bool accept,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw const TripInviteException('Please sign in before responding.');
      }
      if (invite.targetUid != currentUser.uid) {
        throw const TripInviteException('This invite does not belong to you.');
      }
      if (invite.status != TripInviteStatus.pending) {
        throw const TripInviteException('This invite has already been handled.');
      }

      final inviteRef = _invites.doc(invite.id);
      if (!accept) {
        AppLogger.info(
          'TripInviteService.respondToInvite',
          'Rejecting invite ${invite.id} for user ${currentUser.uid}.',
        );
        await inviteRef.update({
          'status': TripInviteStatus.rejected.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.info(
          'TripInviteService.respondToInvite',
          'Invite ${invite.id} marked as rejected.',
        );
        return;
      }

      final tripRef = _firestore
          .collection(FirestoreCollections.trips)
          .doc(invite.tripId);

      AppLogger.info(
        'TripInviteService.respondToInvite',
        'Approving invite ${invite.id}. Adding ${currentUser.uid} to trip ${invite.tripId}.',
      );
      await tripRef.update({
        'memberIds': FieldValue.arrayUnion([currentUser.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info(
        'TripInviteService.respondToInvite',
        'Trip ${invite.tripId} membership update succeeded for ${currentUser.uid}.',
      );

      AppLogger.info(
        'TripInviteService.respondToInvite',
        'Updating invite ${invite.id} status to accepted.',
      );
      await inviteRef.update({
        'status': TripInviteStatus.accepted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info(
        'TripInviteService.respondToInvite',
        'Invite ${invite.id} marked as accepted.',
      );
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'TripInviteService.respondToInvite',
        error,
        stackTrace: stackTrace,
      );
      if (error.code == 'permission-denied') {
        throw TripInviteException(
          'Firestore blocked this action: ${error.message ?? error.code}',
        );
      }
      throw TripInviteException(
        error.message ?? 'Unable to update that invite.',
      );
    }
  }

  static String _senderName(AppUser? user, String? fallbackEmail) {
    final displayName = user?.displayName.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final fullName = user?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final email = fallbackEmail?.trim() ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Admin';
  }
}

class TripInviteException implements Exception {
  final String message;

  const TripInviteException(this.message);
}
