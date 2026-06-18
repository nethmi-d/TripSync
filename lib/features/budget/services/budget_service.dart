import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/app_logger.dart';
import '../models/budget_models.dart';

class BudgetService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  BudgetService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _trip(String tripId) =>
      _firestore.collection(FirestoreCollections.trips).doc(tripId);

  DocumentReference<Map<String, dynamic>> _config(String tripId) =>
      _trip(tripId).collection(FirestoreCollections.budget).doc('config');

  CollectionReference<Map<String, dynamic>> _expenses(String tripId) =>
      _trip(tripId).collection(FirestoreCollections.expenses);

  CollectionReference<Map<String, dynamic>> _settlements(String tripId) =>
      _trip(tripId).collection(FirestoreCollections.settlements);

  Stream<TripBudget?> watchBudget(String tripId) {
    return _config(tripId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : TripBudget.fromMap(data);
    });
  }

  Stream<List<TripExpense>> watchExpenses(String tripId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const []);
    }
    return _expenses(
      tripId,
    ).where('participantIds', arrayContains: uid).snapshots().map((snapshot) {
      final expenses =
          snapshot.docs.map((doc) => TripExpense.fromMap(doc.data())).toList()
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
      return expenses;
    });
  }

  Stream<List<GroupSettlement>> watchSettlements(String tripId) {
    return _settlements(tripId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => GroupSettlement.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<GroupSettlement?> watchMySettlement(String tripId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(null);
    }
    return _settlements(tripId).doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : GroupSettlement.fromMap(data);
    });
  }

  Future<void> saveBudget({
    required String tripId,
    required double totalAmount,
    required String currency,
    required List<BudgetCategory> categories,
  }) async {
    final trip = await _requireTrip(tripId, requireAdmin: true);
    final memberIds = List<String>.from(trip['memberIds'] as List? ?? []);
    if (memberIds.isEmpty) {
      throw const BudgetServiceException('This trip has no members.');
    }
    final allocated = categories.fold<double>(
      0,
      (total, category) => total + category.allocatedAmount,
    );
    if (allocated > totalAmount + 0.001) {
      throw const BudgetServiceException(
        'Category allocations cannot exceed the total budget.',
      );
    }

    try {
      final expenseSnapshot = await _expenses(
        tripId,
      ).where('participantIds', arrayContains: _auth.currentUser!.uid).get();
      final groupExpenses = expenseSnapshot.docs
          .map((doc) => TripExpense.fromMap(doc.data()))
          .where((expense) => expense.isGroupExpense)
          .toList();
      final spentTotal = groupExpenses.fold<double>(
        0,
        (total, expense) => total + expense.amount,
      );
      if (totalAmount + .001 < spentTotal) {
        throw BudgetServiceException(
          'The total budget cannot be lower than the already spent amount.',
        );
      }
      for (final category in categories) {
        final categorySpent = groupExpenses
            .where((expense) => expense.categoryId == category.id)
            .fold<double>(0, (total, expense) => total + expense.amount);
        if (category.allocatedAmount + .001 < categorySpent) {
          throw BudgetServiceException(
            '${category.name} cannot be lower than its already spent amount.',
          );
        }
      }

      final batch = _firestore.batch();
      batch.set(_config(tripId), {
        'totalAmount': totalAmount,
        'currency': currency.trim().toUpperCase(),
        'categories': categories.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedByUid': _auth.currentUser!.uid,
      });

      final share = totalAmount / memberIds.length;
      final existingSettlements = await Future.wait(
        memberIds.map((uid) => _settlements(tripId).doc(uid).get()),
      );
      final existingByMember = {
        for (final snapshot in existingSettlements) snapshot.id: snapshot,
      };
      for (final memberUid in memberIds) {
        final reference = _settlements(tripId).doc(memberUid);
        final existing = existingByMember[memberUid];
        final existingAmount = (existing?.data()?['amount'] as num?)
            ?.toDouble();
        final shareChanged =
            existingAmount == null || (existingAmount - share).abs() > .01;
        batch.set(reference, {
          'memberUid': memberUid,
          'amount': share,
          if (shareChanged) ...{
            'memberPaid': false,
            'adminConfirmed': false,
            'paidAt': null,
            'confirmedAt': null,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'BudgetService.saveBudget',
        error,
        stackTrace: stackTrace,
      );
      throw BudgetServiceException(
        error.code == 'permission-denied'
            ? 'Firestore rules blocked saving this budget.'
            : error.message ?? 'Unable to save the budget.',
      );
    }
  }

  Future<void> addExpense({
    required String tripId,
    required String title,
    required double amount,
    required String? categoryId,
    required String? paidByUid,
    required bool isGroupExpense,
    required ExpenseSplitType? splitType,
    required List<String> participantIds,
    required Map<String, double> shares,
  }) async {
    final trip = await _requireTrip(tripId, requireAdmin: isGroupExpense);
    if (title.trim().isEmpty || amount <= 0) {
      throw const BudgetServiceException('Enter a valid title and amount.');
    }
    if (isGroupExpense) {
      if (categoryId == null) {
        throw const BudgetServiceException(
          'Select a budget category for the group expense.',
        );
      }
    } else {
      if (paidByUid == null || splitType == null || participantIds.isEmpty) {
        throw const BudgetServiceException(
          'Choose who paid, a split method and shared members.',
        );
      }
      final splitTotal = shares.values.fold<double>(
        0,
        (total, item) => total + item,
      );
      if ((splitTotal - amount).abs() > 0.02) {
        throw const BudgetServiceException(
          'The member shares must equal the expense amount.',
        );
      }
    }

    try {
      final reference = _expenses(tripId).doc();
      final visibleMemberIds = isGroupExpense
          ? List<String>.from(trip['memberIds'] as List? ?? [])
          : <String>{...participantIds, paidByUid!}.toList();
      await reference.set({
        'id': reference.id,
        'title': title.trim(),
        'amount': amount,
        'categoryId': categoryId,
        'paidByUid': paidByUid,
        'createdByUid': _auth.currentUser!.uid,
        'isGroupExpense': isGroupExpense,
        'splitType': splitType?.name,
        'participantIds': visibleMemberIds,
        'shares': shares,
        'settledParticipantIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'BudgetService.addExpense',
        error,
        stackTrace: stackTrace,
      );
      throw BudgetServiceException(
        error.code == 'permission-denied'
            ? 'Firestore rules blocked adding this expense.'
            : error.message ?? 'Unable to add the expense.',
      );
    }
  }

  Future<void> updatePrivateExpense({
    required String tripId,
    required String expenseId,
    required String title,
    required double amount,
    required String paidByUid,
    required ExpenseSplitType splitType,
    required List<String> participantIds,
    required Map<String, double> shares,
  }) async {
    await _requireTrip(tripId, requireAdmin: false);
    final uid = _auth.currentUser?.uid;
    final reference = _expenses(tripId).doc(expenseId);
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (data == null) {
      throw const BudgetServiceException('Expense not found.');
    }
    final expense = TripExpense.fromMap(data);
    if (expense.isGroupExpense || expense.createdByUid != uid) {
      throw const BudgetServiceException(
        'Only the creator can edit this private expense.',
      );
    }
    _validatePrivateSplit(
      title: title,
      amount: amount,
      paidByUid: paidByUid,
      participantIds: participantIds,
      shares: shares,
    );
    try {
      await reference.update({
        'title': title.trim(),
        'amount': amount,
        'paidByUid': paidByUid,
        'splitType': splitType.name,
        'participantIds': <String>{...participantIds, paidByUid}.toList(),
        'shares': shares,
        'settledParticipantIds': <String>[],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'BudgetService.updatePrivateExpense',
        error,
        stackTrace: stackTrace,
      );
      throw BudgetServiceException(
        error.code == 'permission-denied'
            ? 'Firestore rules blocked editing this expense.'
            : error.message ?? 'Unable to update the expense.',
      );
    }
  }

  Future<void> deletePrivateExpense({
    required String tripId,
    required String expenseId,
  }) async {
    await _requireTrip(tripId, requireAdmin: false);
    final uid = _auth.currentUser?.uid;
    final reference = _expenses(tripId).doc(expenseId);
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (data == null) return;
    final expense = TripExpense.fromMap(data);
    if (expense.isGroupExpense || expense.createdByUid != uid) {
      throw const BudgetServiceException(
        'Only the creator can delete this private expense.',
      );
    }
    try {
      await reference.delete();
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'BudgetService.deletePrivateExpense',
        error,
        stackTrace: stackTrace,
      );
      throw BudgetServiceException(
        error.code == 'permission-denied'
            ? 'Firestore rules blocked deleting this expense.'
            : error.message ?? 'Unable to delete the expense.',
      );
    }
  }

  Future<void> settleMyPrivateShare({
    required String tripId,
    required String expenseId,
  }) async {
    await _requireTrip(tripId, requireAdmin: false);
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const BudgetServiceException('Please sign in first.');
    }
    try {
      final reference = _expenses(tripId).doc(expenseId);
      final snapshot = await reference.get();
      final data = snapshot.data();
      if (data == null) {
        throw const BudgetServiceException('Expense not found.');
      }
      final expense = TripExpense.fromMap(data);
      AppLogger.info(
        'BudgetService.settleMyPrivateShare',
        'tripId=$tripId expenseId=$expenseId userId=$uid '
            'paidByUid=${expense.paidByUid} '
            'share=${expense.shares[uid]} '
            'settled=${expense.settledParticipantIds.contains(uid)}',
      );
      if (expense.isGroupExpense ||
          expense.paidByUid == uid ||
          !expense.shares.containsKey(uid)) {
        throw const BudgetServiceException(
          'You do not have a payable share in this expense.',
        );
      }
      if (expense.settledParticipantIds.contains(uid)) {
        throw const BudgetServiceException(
          'Your share of this expense is already settled.',
        );
      }
      await reference.update({
        'settledParticipantIds': FieldValue.arrayUnion([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'BudgetService.settleMyPrivateShare',
        error,
        stackTrace: stackTrace,
      );
      throw BudgetServiceException(
        error.code == 'permission-denied'
            ? 'Firestore rules blocked settling this expense.'
            : error.message ?? 'Unable to settle this expense.',
      );
    }
  }

  static void _validatePrivateSplit({
    required String title,
    required double amount,
    required String paidByUid,
    required List<String> participantIds,
    required Map<String, double> shares,
  }) {
    if (title.trim().isEmpty || amount <= 0 || participantIds.isEmpty) {
      throw const BudgetServiceException(
        'Enter a valid expense and select shared members.',
      );
    }
    final splitTotal = shares.values.fold<double>(
      0,
      (total, item) => total + item,
    );
    if ((splitTotal - amount).abs() > 0.02) {
      throw const BudgetServiceException(
        'The member shares must equal the expense amount.',
      );
    }
  }

  Future<void> markMyContributionPaid(String tripId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const BudgetServiceException('Please sign in first.');
    }
    await _settlements(tripId).doc(uid).update({
      'memberPaid': true,
      'adminConfirmed': false,
      'paidAt': FieldValue.serverTimestamp(),
      'confirmedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> confirmContribution({
    required String tripId,
    required String memberUid,
  }) async {
    await _requireTrip(tripId, requireAdmin: true);
    await _settlements(tripId).doc(memberUid).update({
      'adminConfirmed': true,
      'confirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> _requireTrip(
    String tripId, {
    required bool requireAdmin,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const BudgetServiceException('Please sign in first.');
    }
    final snapshot = await _trip(tripId).get();
    final data = snapshot.data();
    if (data == null) {
      throw const BudgetServiceException('Trip not found.');
    }
    final memberIds = List<String>.from(data['memberIds'] as List? ?? []);
    final adminIds = List<String>.from(data['adminIds'] as List? ?? []);
    if (!memberIds.contains(uid)) {
      throw const BudgetServiceException('You are not a member of this trip.');
    }
    if (requireAdmin && !adminIds.contains(uid)) {
      throw const BudgetServiceException('Only trip admins can do this.');
    }
    return data;
  }
}

class BudgetServiceException implements Exception {
  final String message;

  const BudgetServiceException(this.message);
}
