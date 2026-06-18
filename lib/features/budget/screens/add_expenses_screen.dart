import 'package:flutter/material.dart';

import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/user_service.dart';
import '../../trips/models/trip_model.dart';
import '../../trips/services/trip_service.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';

class AddExpensesScreen extends StatefulWidget {
  final String? tripId;
  final TripExpense? expense;

  const AddExpensesScreen({super.key, this.tripId, this.expense});

  @override
  State<AddExpensesScreen> createState() => _AddExpensesScreenState();
}

class _AddExpensesScreenState extends State<AddExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _budgetService = BudgetService();
  final _tripService = TripService();
  final _userService = UserService();
  final _authService = AuthService();
  final Map<String, TextEditingController> _shareControllers = {};

  TripModel? _trip;
  TripBudget? _budget;
  List<AppUser> _members = const [];
  final Set<String> _selectedMemberIds = {};
  ExpenseSplitType _splitType = ExpenseSplitType.equal;
  bool _isGroupExpense = true;
  String? _paidByUid;
  String? _categoryId;
  bool _loading = true;
  bool _saving = false;

  bool get _isAdmin {
    final uid = _authService.currentFirebaseUser?.uid;
    return uid != null && (_trip?.adminIds.contains(uid) ?? false);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (final controller in _shareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final tripId = widget.tripId;
    if (tripId == null) {
      setState(() => _loading = false);
      return;
    }
    final trip = await _tripService.getTrip(tripId);
    if (trip == null) {
      setState(() => _loading = false);
      return;
    }
    final members = (await Future.wait(
      trip.memberIds.map(_userService.getUser),
    )).whereType<AppUser>().toList();
    final budget = await _budgetService.watchBudget(tripId).first;
    if (!mounted) return;
    final currentUid = _authService.currentFirebaseUser?.uid;
    final editingExpense = widget.expense;
    setState(() {
      _trip = trip;
      _members = members;
      _budget = budget;
      if (editingExpense == null) {
        _isGroupExpense = trip.adminIds.contains(currentUid);
        _paidByUid = currentUid;
        _selectedMemberIds.addAll(trip.memberIds);
      } else {
        _isGroupExpense = false;
        _titleController.text = editingExpense.title;
        _amountController.text = editingExpense.amount.toStringAsFixed(2);
        _paidByUid = editingExpense.paidByUid;
        _categoryId = editingExpense.categoryId;
        _splitType = editingExpense.splitType ?? ExpenseSplitType.equal;
        _selectedMemberIds.addAll(editingExpense.shares.keys);
        if (_splitType == ExpenseSplitType.custom) {
          for (final share in editingExpense.shares.entries) {
            _shareControllers[share.key] = TextEditingController(
              text: share.value.toStringAsFixed(2),
            );
          }
        }
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _trip == null) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final shares = <String, double>{};
    if (!_isGroupExpense && _splitType == ExpenseSplitType.equal) {
      final share = amount / _selectedMemberIds.length;
      for (final uid in _selectedMemberIds) {
        shares[uid] = share;
      }
    } else if (!_isGroupExpense && _splitType == ExpenseSplitType.direct) {
      final debtor = _selectedMemberIds.isEmpty
          ? null
          : _selectedMemberIds.first;
      if (debtor != null) shares[debtor] = amount;
    } else if (!_isGroupExpense) {
      for (final uid in _selectedMemberIds) {
        shares[uid] = double.tryParse(_shareControllers[uid]?.text ?? '') ?? 0;
      }
    }

    setState(() => _saving = true);
    try {
      if (widget.expense == null) {
        await _budgetService.addExpense(
          tripId: _trip!.id,
          title: _titleController.text,
          amount: amount,
          categoryId: _categoryId,
          paidByUid: _isGroupExpense ? null : _paidByUid,
          isGroupExpense: _isGroupExpense,
          splitType: _isGroupExpense ? null : _splitType,
          participantIds: _isGroupExpense
              ? const []
              : _selectedMemberIds.toList(),
          shares: shares,
        );
      } else {
        await _budgetService.updatePrivateExpense(
          tripId: _trip!.id,
          expenseId: widget.expense!.id,
          title: _titleController.text,
          amount: amount,
          paidByUid: _paidByUid!,
          splitType: _splitType,
          participantIds: _selectedMemberIds.toList(),
          shares: shares,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on BudgetServiceException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_trip == null) {
      return const Scaffold(body: Center(child: Text('Trip not found.')));
    }
    final groupCategoriesMissing =
        _isGroupExpense && !(_budget?.categories.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: Text(
          widget.expense == null ? 'Add Expense' : 'Edit Private Expense',
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (_isAdmin && widget.expense == null) ...[
              const _FieldLabel('Expense type'),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.groups_outlined),
                    label: Text('Group'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.person_outline),
                    label: Text('Private'),
                  ),
                ],
                selected: {_isGroupExpense},
                onSelectionChanged: (value) {
                  setState(() => _isGroupExpense = value.first);
                },
              ),
              const SizedBox(height: 18),
            ],
            const _FieldLabel('Expense title *'),
            TextFormField(
              controller: _titleController,
              decoration: _decoration('e.g. Dinner at restaurant'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Amount *'),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _decoration(
                '0.00',
                prefix: '${_budget?.currency ?? 'LKR'} ',
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                return amount == null || amount <= 0
                    ? 'Enter a valid amount'
                    : null;
              },
            ),
            if (_isGroupExpense) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF2563EB),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This expense is paid from the shared group wallet.',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (groupCategoriesMissing) ...[
                const SizedBox(height: 10),
                const Text(
                  'Set up at least one budget category before adding a group expense.',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              const _FieldLabel('Paid by *'),
              DropdownButtonFormField<String>(
                initialValue: _paidByUid,
                decoration: _decoration('Select member'),
                items: _members
                    .map(
                      (user) => DropdownMenuItem(
                        value: user.uid,
                        child: Text(_memberName(user)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _paidByUid = value),
                validator: (value) => value == null ? 'Select who paid' : null,
              ),
            ],
            if (_isGroupExpense &&
                (_budget?.categories.isNotEmpty ?? false)) ...[
              const SizedBox(height: 16),
              const _FieldLabel('Budget category *'),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: _decoration('Select category'),
                items: _budget!.categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
                validator: (value) =>
                    value == null ? 'Select a category' : null,
              ),
            ],
            if (!_isGroupExpense) ...[
              const SizedBox(height: 20),
              const _FieldLabel('Split method'),
              SegmentedButton<ExpenseSplitType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ExpenseSplitType.equal,
                    label: Text('Equal'),
                  ),
                  ButtonSegment(
                    value: ExpenseSplitType.direct,
                    label: Text('Direct'),
                  ),
                  ButtonSegment(
                    value: ExpenseSplitType.custom,
                    label: Text('Custom'),
                  ),
                ],
                selected: {_splitType},
                onSelectionChanged: (value) {
                  setState(() {
                    _splitType = value.first;
                    if (_splitType == ExpenseSplitType.direct &&
                        _selectedMemberIds.length > 1) {
                      final first = _selectedMemberIds.first;
                      _selectedMemberIds
                        ..clear()
                        ..add(first);
                    }
                  });
                },
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Shared members *'),
              ..._members.map(_memberSelector),
              if (_selectedMemberIds.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Select at least one member.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed:
                    _saving ||
                        groupCategoriesMissing ||
                        (!_isGroupExpense && _selectedMemberIds.isEmpty)
                    ? null
                    : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.expense != null
                            ? 'Save private expense'
                            : _isGroupExpense
                            ? 'Add group expense'
                            : 'Add private expense',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberSelector(AppUser user) {
    final selected = _selectedMemberIds.contains(user.uid);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: user.photoUrl == null
                ? null
                : NetworkImage(user.photoUrl!),
            child: user.photoUrl == null
                ? Text(_initials(_memberName(user)))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _memberName(user),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (_splitType == ExpenseSplitType.custom && selected)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 82,
                  child: TextField(
                    controller: _shareControllers.putIfAbsent(
                      user.uid,
                      () => TextEditingController(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _decoration('0.00'),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove member',
                  onPressed: () {
                    setState(() => _selectedMemberIds.remove(user.uid));
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            )
          else
            Checkbox(
              value: selected,
              onChanged: (value) {
                setState(() {
                  if (_splitType == ExpenseSplitType.direct) {
                    _selectedMemberIds
                      ..clear()
                      ..add(user.uid);
                  } else if (value == true) {
                    _selectedMemberIds.add(user.uid);
                  } else {
                    _selectedMemberIds.remove(user.uid);
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  static InputDecoration _decoration(String hint, {String? prefix}) =>
      InputDecoration(
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

String _memberName(AppUser user) =>
    user.displayName.trim().isNotEmpty ? user.displayName : user.fullName;

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0]).join().toUpperCase();
}
