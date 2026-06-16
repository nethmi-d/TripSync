import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String id;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final List<String> memberIds;
  final String? coverImageUrl;
  final String? coverImagePublicId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripModel({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.memberIds,
    required this.coverImageUrl,
    required this.coverImagePublicId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdBy': createdBy,
      'memberIds': memberIds,
      'coverImageUrl': coverImageUrl,
      'coverImagePublicId': coverImagePublicId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      startDate: _dateFrom(map['startDate']),
      endDate: _dateFrom(map['endDate']),
      createdBy: map['createdBy'] as String? ?? '',
      memberIds: List<String>.from(map['memberIds'] as List? ?? const []),
      coverImageUrl: map['coverImageUrl'] as String?,
      coverImagePublicId: map['coverImagePublicId'] as String?,
      createdAt: _dateFrom(map['createdAt']),
      updatedAt: _dateFrom(map['updatedAt']),
    );
  }

  static DateTime _dateFrom(Object? value) {
    return value is Timestamp ? value.toDate() : DateTime.now().toUtc();
  }
}
