import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? photoPublicId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.photoUrl,
    required this.photoPublicId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'photoPublicId': photoPublicId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      photoPublicId: map['photoPublicId'] as String?,
      createdAt: _dateFrom(map['createdAt']),
      updatedAt: _dateFrom(map['updatedAt']),
    );
  }

  static DateTime _dateFrom(Object? value) {
    return value is Timestamp ? value.toDate() : DateTime.now().toUtc();
  }
}
