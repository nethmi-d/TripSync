import 'package:cloud_firestore/cloud_firestore.dart';

enum TripInviteStatus { pending, accepted, rejected, cancelled }

class TripInvite {
  final String id;
  final String tripId;
  final String tripName;
  final String? tripCoverImageUrl;
  final String senderUid;
  final String senderName;
  final String senderEmail;
  final String targetUid;
  final String targetEmail;
  final String requestedRole;
  final TripInviteStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripInvite({
    required this.id,
    required this.tripId,
    required this.tripName,
    required this.tripCoverImageUrl,
    required this.senderUid,
    required this.senderName,
    required this.senderEmail,
    required this.targetUid,
    required this.targetEmail,
    required this.requestedRole,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'tripName': tripName,
      'tripCoverImageUrl': tripCoverImageUrl,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'targetUid': targetUid,
      'targetEmail': targetEmail,
      'requestedRole': requestedRole,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TripInvite.fromMap(Map<String, dynamic> map) {
    return TripInvite(
      id: map['id'] as String? ?? '',
      tripId: map['tripId'] as String? ?? '',
      tripName: map['tripName'] as String? ?? '',
      tripCoverImageUrl: map['tripCoverImageUrl'] as String?,
      senderUid: map['senderUid'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderEmail: map['senderEmail'] as String? ?? '',
      targetUid: map['targetUid'] as String? ?? '',
      targetEmail: map['targetEmail'] as String? ?? '',
      requestedRole: map['requestedRole'] as String? ?? 'Member',
      status: _statusFrom(map['status'] as String?),
      createdAt: _dateFrom(map['createdAt']),
      updatedAt: _dateFrom(map['updatedAt']),
    );
  }

  static TripInviteStatus _statusFrom(String? value) {
    return TripInviteStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TripInviteStatus.pending,
    );
  }

  static DateTime _dateFrom(Object? value) {
    return value is Timestamp ? value.toDate() : DateTime.now().toUtc();
  }
}
