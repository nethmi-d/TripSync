import 'package:cloud_firestore/cloud_firestore.dart';

class ItineraryActivity {
  final String id;
  final String tripId;
  final int dayIndex;
  final String title;
  final String? time;
  final String location;
  final String? iconKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ItineraryActivity({
    required this.id,
    required this.tripId,
    required this.dayIndex,
    required this.title,
    required this.time,
    required this.location,
    required this.iconKey,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'dayIndex': dayIndex,
      'title': title,
      'time': time,
      'location': location,
      'iconKey': iconKey,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ItineraryActivity.fromMap(Map<String, dynamic> map) {
    return ItineraryActivity(
      id: map['id'] as String? ?? '',
      tripId: map['tripId'] as String? ?? '',
      dayIndex: map['dayIndex'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      time: map['time'] as String?,
      location: map['location'] as String? ?? '',
      iconKey: map['iconKey'] as String?,
      createdAt: _dateFrom(map['createdAt']),
      updatedAt: _dateFrom(map['updatedAt']),
    );
  }

  static DateTime _dateFrom(Object? value) {
    return value is Timestamp ? value.toDate() : DateTime.now().toUtc();
  }
}
