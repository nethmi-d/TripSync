import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetCategory {
  final String id;
  final String name;
  final double allocatedAmount;
  final int colorValue;

  const BudgetCategory({
    required this.id,
    required this.name,
    required this.allocatedAmount,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'allocatedAmount': allocatedAmount,
    'colorValue': colorValue,
  };

  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    return BudgetCategory(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      allocatedAmount: (map['allocatedAmount'] as num?)?.toDouble() ?? 0,
      colorValue: map['colorValue'] as int? ?? 0xFF2563EB,
    );
  }
}

class TripBudget {
  final double totalAmount;
  final String currency;
  final List<BudgetCategory> categories;
  final DateTime updatedAt;

  const TripBudget({
    required this.totalAmount,
    required this.currency,
    required this.categories,
    required this.updatedAt,
  });

  factory TripBudget.fromMap(Map<String, dynamic> map) {
    return TripBudget(
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'LKR',
      categories: (map['categories'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => BudgetCategory.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
      updatedAt: _dateFrom(map['updatedAt']),
    );
  }
}

enum ExpenseSplitType { equal, direct, custom }

class TripExpense {
  final String id;
  final String title;
  final double amount;
  final String? categoryId;
  final String? paidByUid;
  final String createdByUid;
  final bool isGroupExpense;
  final ExpenseSplitType? splitType;
  final List<String> participantIds;
  final Map<String, double> shares;
  final List<String> settledParticipantIds;
  final DateTime createdAt;

  const TripExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.paidByUid,
    required this.createdByUid,
    required this.isGroupExpense,
    required this.splitType,
    required this.participantIds,
    required this.shares,
    required this.settledParticipantIds,
    required this.createdAt,
  });

  factory TripExpense.fromMap(Map<String, dynamic> map) {
    final rawShares = Map<String, dynamic>.from(map['shares'] as Map? ?? {});
    return TripExpense(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      categoryId: map['categoryId'] as String?,
      paidByUid: map['paidByUid'] as String?,
      createdByUid: map['createdByUid'] as String? ?? '',
      isGroupExpense: map['isGroupExpense'] as bool? ?? false,
      splitType: map['splitType'] == null
          ? null
          : ExpenseSplitType.values.firstWhere(
              (type) => type.name == map['splitType'],
              orElse: () => ExpenseSplitType.equal,
            ),
      participantIds: List<String>.from(map['participantIds'] as List? ?? []),
      shares: rawShares.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      settledParticipantIds: List<String>.from(
        map['settledParticipantIds'] as List? ?? [],
      ),
      createdAt: _dateFrom(map['createdAt']),
    );
  }
}

class GroupSettlement {
  final String memberUid;
  final double amount;
  final bool memberPaid;
  final bool adminConfirmed;
  final DateTime? paidAt;
  final DateTime? confirmedAt;

  const GroupSettlement({
    required this.memberUid,
    required this.amount,
    required this.memberPaid,
    required this.adminConfirmed,
    required this.paidAt,
    required this.confirmedAt,
  });

  factory GroupSettlement.fromMap(Map<String, dynamic> map) {
    return GroupSettlement(
      memberUid: map['memberUid'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      memberPaid: map['memberPaid'] as bool? ?? false,
      adminConfirmed: map['adminConfirmed'] as bool? ?? false,
      paidAt: _nullableDateFrom(map['paidAt']),
      confirmedAt: _nullableDateFrom(map['confirmedAt']),
    );
  }
}

DateTime _dateFrom(Object? value) {
  return value is Timestamp ? value.toDate() : DateTime.now().toUtc();
}

DateTime? _nullableDateFrom(Object? value) {
  return value is Timestamp ? value.toDate() : null;
}
