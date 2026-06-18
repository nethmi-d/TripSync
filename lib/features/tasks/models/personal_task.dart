import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalTask {
  final String id;
  final String title;
  final DateTime? dueDate;
  final String priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonalTask({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
      'priority': priority,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PersonalTask.fromMap(String id, Map<String, dynamic> map) {
    return PersonalTask(
      id: id,
      title: map['title'] as String? ?? '',
      dueDate: _readOptionalDate(map['dueDate']),
      priority: _readPriority(map['priority']),
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime _readDate(Object? value) {
    return value is Timestamp ? value.toDate() : DateTime.now();
  }

  static DateTime? _readOptionalDate(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }

  static String _readPriority(Object? value) {
    final priority = value as String?;
    return const {'low', 'medium', 'high'}.contains(priority)
        ? priority!
        : 'medium';
  }
}