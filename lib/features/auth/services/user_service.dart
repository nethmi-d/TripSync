import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/app_logger.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  Future<void> createUser(AppUser user) async {
    try {
      AppLogger.info(
        'UserService',
        'Creating Firestore profile for ${user.uid}.',
      );
      await _users.doc(user.uid).set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      AppLogger.error('UserService.createUser', error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<AppUser?> getUser(String uid) async {
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();

    return data == null ? null : AppUser.fromMap(data);
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final fallbackSnapshot = await _users
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (fallbackSnapshot.docs.isNotEmpty) {
      return AppUser.fromMap(fallbackSnapshot.docs.first.data());
    }

    return null;
  }

  Future<List<AppUser>> searchUsersByEmailPrefix(
    String query, {
    int limit = 8,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final snapshot = await _users
        .orderBy('email')
        .startAt([normalizedQuery])
        .endAt(['$normalizedQuery\uf8ff'])
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> changes) async {
    try {
      AppLogger.info('UserService', 'Updating Firestore profile for $uid.');
      await _users.doc(uid).update({...changes, 'updatedAt': Timestamp.now()});
    } catch (error, stackTrace) {
      AppLogger.error('UserService.updateUser', error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      AppLogger.info('UserService', 'Deleting Firestore profile for $uid.');
      await _users.doc(uid).delete();
    } catch (error, stackTrace) {
      AppLogger.error('UserService.deleteUser', error, stackTrace: stackTrace);
      rethrow;
    }
  }
}
