import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/app_logger.dart';
import '../models/personal_task.dart';

class TaskService {
  static const _tasksField = 'personalTasks';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  TaskService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDocument(String userId) {
    return _firestore.collection(FirestoreCollections.users).doc(userId);
  }

  Stream<List<PersonalTask>> watchMyTasks() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.error(
        const TaskServiceException('Please sign in to manage your tasks.'),
      );
    }

    return _userDocument(userId).snapshots().map((snapshot) {
      final rawTasks = snapshot.data()?[_tasksField] as List? ?? const [];
      final tasks = rawTasks
          .whereType<Map>()
          .map((value) {
            final map = Map<String, dynamic>.from(value);
            return PersonalTask.fromMap(map['id'] as String? ?? '', map);
          })
          .where((task) => task.id.isNotEmpty && task.title.isNotEmpty)
          .toList();
      tasks.sort((left, right) {
        if (left.isCompleted != right.isCompleted) {
          return left.isCompleted ? 1 : -1;
        }
        if (!left.isCompleted) {
          final leftDue = left.dueDate;
          final rightDue = right.dueDate;
          if (leftDue != null && rightDue != null) {
            final dueCompare = leftDue.compareTo(rightDue);
            if (dueCompare != 0) return dueCompare;
          } else if (leftDue != null) {
            return -1;
          } else if (rightDue != null) {
            return 1;
          }
        }
        return right.createdAt.compareTo(left.createdAt);
      });
      return tasks;
    });
  }

  Future<void> addTask({
    required String title,
    required DateTime dueDate,
    required String priority,
  }) async {
    final cleanTitle = _validTitle(title);
    final cleanPriority = _validPriority(priority);
    final now = DateTime.now();
    final taskId = _firestore.collection(FirestoreCollections.users).doc().id;
    final task = PersonalTask(
      id: taskId,
      title: cleanTitle,
      dueDate: dueDate,
      priority: cleanPriority,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
    await _changeTasks('addTask', (tasks) => [...tasks, task]);
  }

  Future<void> updateTask({
    required PersonalTask task,
    required String title,
    required DateTime dueDate,
    required String priority,
  }) async {
    final cleanTitle = _validTitle(title);
    final cleanPriority = _validPriority(priority);
    await _changeTasks(
      'updateTask',
      (tasks) => tasks
          .map(
            (item) => item.id == task.id
                ? PersonalTask(
                    id: item.id,
                    title: cleanTitle,
                    dueDate: dueDate,
                    priority: cleanPriority,
                    isCompleted: item.isCompleted,
                    createdAt: item.createdAt,
                    updatedAt: DateTime.now(),
                  )
                : item,
          )
          .toList(),
    );
  }

  Future<void> setCompleted(PersonalTask task, bool isCompleted) async {
    await _changeTasks(
      'setCompleted',
      (tasks) => tasks
          .map(
            (item) => item.id == task.id
                ? PersonalTask(
                    id: item.id,
                    title: item.title,
                    dueDate: item.dueDate,
                    priority: item.priority,
                    isCompleted: isCompleted,
                    createdAt: item.createdAt,
                    updatedAt: DateTime.now(),
                  )
                : item,
          )
          .toList(),
    );
  }

  Future<void> deleteTask(PersonalTask task) async {
    await _changeTasks(
      'deleteTask',
      (tasks) => tasks.where((item) => item.id != task.id).toList(),
    );
  }

  Future<void> _changeTasks(
    String operation,
    List<PersonalTask> Function(List<PersonalTask> tasks) change,
  ) async {
    final userId = _requireUserId();
    final userDocument = _userDocument(userId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocument);
        if (!snapshot.exists) {
          throw const TaskServiceException('Your user profile was not found.');
        }
        final rawTasks = snapshot.data()?[_tasksField] as List? ?? const [];
        final tasks = rawTasks.whereType<Map>().map((value) {
          final map = Map<String, dynamic>.from(value);
          return PersonalTask.fromMap(map['id'] as String? ?? '', map);
        }).toList();
        final updatedTasks = change(tasks);
        transaction.update(userDocument, {
          _tasksField: updatedTasks.map((task) => task.toMap()).toList(),
        });
      });
    } on TaskServiceException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('TaskService.$operation', error, stackTrace: stackTrace);
      if (error.code == 'permission-denied') {
        throw const TaskServiceException(
          'Firebase blocked access to your user profile. Check the users rule.',
        );
      }
      throw TaskServiceException(error.message ?? 'Unable to save the task.');
    }
  }

  String _requireUserId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw const TaskServiceException('Please sign in to manage your tasks.');
    }
    return userId;
  }

  static String _validTitle(String value) {
    final title = value.trim();
    if (title.isEmpty) {
      throw const TaskServiceException('Task title is required.');
    }
    if (title.length > 120) {
      throw const TaskServiceException(
        'Task title must be 120 characters or fewer.',
      );
    }
    return title;
  }

  static String _validPriority(String value) {
    if (!const {'low', 'medium', 'high'}.contains(value)) {
      throw const TaskServiceException('Choose a valid priority.');
    }
    return value;
  }
}

class TaskServiceException implements Exception {
  final String message;

  const TaskServiceException(this.message);
}