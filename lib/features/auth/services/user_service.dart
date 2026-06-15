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
