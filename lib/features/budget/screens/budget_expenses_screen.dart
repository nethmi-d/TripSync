import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/user_service.dart';
import '../../trips/models/trip_model.dart';
import '../../trips/services/trip_service.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';
import 'add_expenses_screen.dart';

class BudgetExpensesScreen extends StatefulWidget {
  final String? tripId;

  const BudgetExpensesScreen({super.key, this.tripId});

  @override
  State<BudgetExpensesScreen> createState() => _BudgetExpensesScreenState();
}

class _BudgetExpensesScreenState extends State<BudgetExpensesScreen> {
  final _budgetService = BudgetService();
  final _tripService = TripService();
  final _userService = UserService();
  final _authService = AuthService();
  late Future<_BudgetContext?> _contextFuture;

  @override
  void initState() {
    super.initState();
    _contextFuture = _loadContext();
  }

  Future<_BudgetContext?> _loadContext() async {
    final tripId = widget.tripId;
    if (tripId == null) return null;
    final trip = await _tripService.getTrip(tripId);
    if (trip == null) return null;
    final members = (await Future.wait(
      trip.memberIds.map(_userService.getUser),
    )).whereType<AppUser>().toList();
    return _BudgetContext(trip: trip, members: members);
  }

  Future<void> _openExpense(String tripId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.addExpenses,
      arguments: tripId,
    );
  }

  Future<void> _editPrivateExpense(String tripId, TripExpense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpensesScreen(tripId: tripId, expense: expense),
      ),
    );
  }

  Future<void> _deletePrivateExpense(String tripId, TripExpense expense) async {
    final confirmed = await _confirm(
      title: 'Delete private expense?',
      message: 'This permanently removes "${expense.title}" and its split.',
      action: 'Delete',
    );
    if (confirmed != true) return;
    try {
      await _budgetService.deletePrivateExpense(
        tripId: tripId,
        expenseId: expense.id,
      );
    } on BudgetServiceException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _openBudgetSetup({
    required TripModel trip,
    required TripBudget? budget,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _BudgetSetupDialog(
        trip: trip,
        budget: budget,
        service: _budgetService,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Budget updated.')));
    }
  }

  Future<void> _markPaid(String tripId) async {
    final confirmed = await _confirm(
      title: 'Mark contribution as paid?',
      message: 'The trip admins will be asked to confirm your payment.',
      action: 'I have paid',
    );
    if (confirmed != true) return;
    try {
      await _budgetService.markMyContributionPaid(tripId);
    } on BudgetServiceException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _confirmMemberPayment(String tripId, String memberUid) async {
    final confirmed = await _confirm(
      title: 'Confirm received payment?',
      message: 'This marks the member contribution as fully settled.',
      action: 'Confirm',
    );
    if (confirmed != true) return;
    try {
      await _budgetService.confirmContribution(
        tripId: tripId,
        memberUid: memberUid,
      );
    } on BudgetServiceException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BudgetContext?>(
      future: _contextFuture,
      builder: (context, contextSnapshot) {
        if (contextSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = contextSnapshot.data;
        if (data == null) {
          return const Scaffold(body: Center(child: Text('Trip not found.')));
        }
        final uid = _authService.currentFirebaseUser?.uid;
        final isAdmin = uid != null && data.trip.adminIds.contains(uid);

        return Scaffold(
          backgroundColor: const Color(0xFFF4F8FC),
          body: Column(
            children: [
              _BudgetHeader(
                tripName: data.trip.name,
                isAdmin: isAdmin,
                onBack: () => Navigator.pop(context),
                onSettings: () async {
                  final budget = await _budgetService
                      .watchBudget(data.trip.id)
                      .first;
                  if (mounted) {
                    _openBudgetSetup(trip: data.trip, budget: budget);
                  }
                },
              ),
              Expanded(
                child: StreamBuilder<TripBudget?>(
                  stream: _budgetService.watchBudget(data.trip.id),
                  builder: (context, budgetSnapshot) {
                    final budget = budgetSnapshot.data;
                    if (budgetSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (budget == null) {
                      return _EmptyBudget(
                        isAdmin: isAdmin,
                        onSetup: () =>
                            _openBudgetSetup(trip: data.trip, budget: null),
                      );
                    }
                    return StreamBuilder<List<TripExpense>>(
                      stream: _budgetService.watchExpenses(data.trip.id),
                      builder: (context, expenseSnapshot) {
                        final expenses =
                            expenseSnapshot.data ?? const <TripExpense>[];
                        return StreamBuilder<List<GroupSettlement>>(
                          stream: _budgetService.watchSettlements(data.trip.id),
                          builder: (context, settlementSnapshot) {
                            final settlements =
                                settlementSnapshot.data ??
                                const <GroupSettlement>[];
                            return _BudgetBody(
                              trip: data.trip,
                              members: data.members,
                              budget: budget,
                              expenses: expenses,
                              settlements: settlements,
                              currentUid: uid,
                              isAdmin: isAdmin,
                              onAddExpense: () => _openExpense(data.trip.id),
                              onEditExpense: (expense) =>
                                  _editPrivateExpense(data.trip.id, expense),
                              onDeleteExpense: (expense) =>
                                  _deletePrivateExpense(data.trip.id, expense),
                              onMarkPaid: () => _markPaid(data.trip.id),
                              onConfirm: (memberUid) => _confirmMemberPayment(
                                data.trip.id,
                                memberUid,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BudgetHeader extends StatelessWidget {
  final String tripName;
  final bool isAdmin;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const _BudgetHeader({
    required this.tripName,
    required this.isAdmin,
    required this.onBack,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 54, 16, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              ),
              const Expanded(
                child: Text(
                  'Budget & Expenses',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isAdmin)
                _BudgetHeaderAction(
                  tooltip: 'Budget settings',
                  icon: Icons.tune_rounded,
                  onTap: onSettings,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 4),
            child: Text(
              '$tripName - Plan, split and settle together',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetHeaderAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _BudgetHeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: const Color(0xFF2563EB), size: 21),
          ),
        ),
      ),
    );
  }
}

class _BudgetBody extends StatelessWidget {
  final TripModel trip;
  final List<AppUser> members;
  final TripBudget budget;
  final List<TripExpense> expenses;
  final List<GroupSettlement> settlements;
  final String? currentUid;
  final bool isAdmin;
  final VoidCallback onAddExpense;
  final ValueChanged<TripExpense> onEditExpense;
  final ValueChanged<TripExpense> onDeleteExpense;
  final VoidCallback onMarkPaid;
  final ValueChanged<String> onConfirm;

  const _BudgetBody({
    required this.trip,
    required this.members,
    required this.budget,
    required this.expenses,
    required this.settlements,
    required this.currentUid,
    required this.isAdmin,
    required this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onMarkPaid,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final groupExpenses = expenses
        .where((item) => item.isGroupExpense)
        .toList();
    final spent = groupExpenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final remaining = budget.totalAmount - spent;
    final ratio = budget.totalAmount <= 0 ? 0.0 : spent / budget.totalAmount;
    final userMap = {for (final member in members) member.uid: member};
    final matchingSettlements = settlements.where(
      (item) => item.memberUid == currentUid,
    );
    final mySettlement = matchingSettlements.isEmpty
        ? null
        : matchingSettlements.first;
    final alertMessage = _criticalAlert(groupExpenses, budget);
    final privateDebts = _privateDebtEntries(
      expenses: expenses,
      currentUid: currentUid,
      users: userMap,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (alertMessage != null) _BudgetAlert(message: alertMessage),
        _OverviewCard(
          currency: budget.currency,
          total: budget.totalAmount,
          spent: spent,
          remaining: remaining,
          ratio: ratio,
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Budget by Category',
          child: Column(
            children: budget.categories.map((category) {
              final categorySpent = groupExpenses
                  .where((item) => item.categoryId == category.id)
                  .fold<double>(0, (sum, item) => sum + item.amount);
              return _CategoryProgress(
                category: category,
                spent: categorySpent,
                currency: budget.currency,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Recent Expenses',
          trailing: TextButton.icon(
            onPressed: onAddExpense,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(isAdmin ? 'Add expense' : 'Private expense'),
          ),
          child: expenses.isEmpty
              ? const _EmptySection(text: 'No expenses recorded yet.')
              : Column(
                  children: expenses.take(8).map((expense) {
                    final payer = expense.paidByUid == null
                        ? null
                        : userMap[expense.paidByUid];
                    final matchingCategories = budget.categories.where(
                      (item) => item.id == expense.categoryId,
                    );
                    final category = matchingCategories.isEmpty
                        ? null
                        : matchingCategories.first;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: expense.isGroupExpense
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFDBEAFE),
                        child: Icon(
                          expense.isGroupExpense
                              ? Icons.groups_outlined
                              : Icons.person_outline,
                          color: expense.isGroupExpense
                              ? const Color(0xFF059669)
                              : const Color(0xFF2563EB),
                        ),
                      ),
                      title: Text(
                        expense.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        expense.isGroupExpense
                            ? 'Group wallet${category == null ? '' : ' - ${category.name}'}'
                            : 'Paid by ${payer == null ? 'member' : _name(payer)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _money(budget.currency, expense.amount),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (!expense.isGroupExpense &&
                              expense.createdByUid == currentUid) ...[
                            const SizedBox(width: 5),
                            _ExpenseActionIcon(
                              tooltip: 'Edit private expense',
                              icon: Icons.edit_outlined,
                              color: const Color(0xFF2563EB),
                              onTap: () => onEditExpense(expense),
                            ),
                            const SizedBox(width: 4),
                            _ExpenseActionIcon(
                              tooltip: 'Delete private expense',
                              icon: Icons.delete_outline,
                              color: const Color(0xFFDC2626),
                              onTap: () => onDeleteExpense(expense),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        if (privateDebts.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Private Expense Summary',
            child: Column(
              children: privateDebts.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: entry.youOwe
                        ? const Color(0xFFFFF7ED)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.youOwe
                            ? Icons.north_east_rounded
                            : Icons.south_west_rounded,
                        color: entry.youOwe
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.youOwe
                              ? 'You owe ${entry.memberName}'
                              : '${entry.memberName} owes you',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _money(budget.currency, entry.amount),
                        style: TextStyle(
                          color: entry.youOwe
                              ? const Color(0xFFEA580C)
                              : const Color(0xFF059669),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Group Settlement',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_money(budget.currency, budget.totalAmount / trip.memberIds.length)} per member',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (mySettlement != null &&
                  !mySettlement.memberPaid &&
                  !mySettlement.adminConfirmed)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onMarkPaid,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('I have paid'),
                  ),
                ),
              ...settlements.map((settlement) {
                final user = userMap[settlement.memberUid];
                final state = settlement.adminConfirmed
                    ? 'Settled'
                    : settlement.memberPaid
                    ? 'Awaiting confirmation'
                    : 'Pending';
                final color = settlement.adminConfirmed
                    ? const Color(0xFF059669)
                    : const Color(0xFFF59E0B);
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .07),
                    border: Border.all(color: color.withValues(alpha: .35)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Text(
                          _initials(user == null ? '?' : _name(user)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user == null ? 'Trip member' : _name(user),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _StatusTag(label: state, color: color),
                          ],
                        ),
                      ),
                      if (isAdmin &&
                          settlement.memberPaid &&
                          !settlement.adminConfirmed)
                        IconButton(
                          tooltip: 'Confirm payment',
                          onPressed: () => onConfirm(settlement.memberUid),
                          icon: const Icon(
                            Icons.verified_outlined,
                            color: Color(0xFF059669),
                          ),
                        )
                      else
                        Icon(
                          settlement.adminConfirmed
                              ? Icons.check_circle
                              : Icons.schedule_rounded,
                          color: color,
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  static String? _criticalAlert(List<TripExpense> expenses, TripBudget budget) {
    final spent = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    if (budget.totalAmount > 0 && spent >= budget.totalAmount) {
      return 'The trip budget has been fully used.';
    }
    if (budget.totalAmount > 0 && spent / budget.totalAmount >= .8) {
      return 'Critical budget warning: more than 80% of the trip budget is used.';
    }
    for (final category in budget.categories) {
      final categorySpent = expenses
          .where((item) => item.categoryId == category.id)
          .fold<double>(0, (sum, item) => sum + item.amount);
      if (category.allocatedAmount > 0 &&
          categorySpent >= category.allocatedAmount) {
        return '${category.name} has reached its allocated budget.';
      }
    }
    return null;
  }
}

class _AddBudgetCategoryDialog extends StatefulWidget {
  final int colorValue;
  final BudgetCategory? category;
  final double maxAmount;

  const _AddBudgetCategoryDialog({
    required this.colorValue,
    required this.maxAmount,
    this.category,
  });

  @override
  State<_AddBudgetCategoryDialog> createState() =>
      _AddBudgetCategoryDialogState();
}

class _AddBudgetCategoryDialogState extends State<_AddBudgetCategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _amountController = TextEditingController(
      text: widget.category?.allocatedAmount.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (_nameController.text.trim().isEmpty || amount == null || amount < 0) {
      setState(() => _error = 'Enter a category name and valid amount.');
      return;
    }
    if (amount > widget.maxAmount + .001) {
      setState(
        () => _error =
            'Maximum available allocation is ${widget.maxAmount.toStringAsFixed(2)}.',
      );
      return;
    }
    Navigator.pop(
      context,
      BudgetCategory(
        id:
            widget.category?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        allocatedAmount: amount,
        colorValue: widget.category?.colorValue ?? widget.colorValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.category_outlined, color: Color(0xFF2563EB)),
          SizedBox(width: 10),
          Text('Category Details'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: _budgetInputDecoration(
              label: 'Category name',
              hint: 'e.g. Accommodation',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _budgetInputDecoration(
              label: 'Allocated amount',
              hint: '0.00',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
          ),
          child: Text(
            widget.category == null ? 'Add Category' : 'Save Changes',
          ),
        ),
      ],
    );
  }
}

class _BudgetSetupDialog extends StatefulWidget {
  final TripModel trip;
  final TripBudget? budget;
  final BudgetService service;

  const _BudgetSetupDialog({
    required this.trip,
    required this.budget,
    required this.service,
  });

  @override
  State<_BudgetSetupDialog> createState() => _BudgetSetupDialogState();
}

class _BudgetSetupDialogState extends State<_BudgetSetupDialog> {
  late final TextEditingController _totalController;
  late String _selectedCurrency;
  late List<BudgetCategory> _categories;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _totalController = TextEditingController(
      text: widget.budget?.totalAmount.toStringAsFixed(2) ?? '',
    );
    _selectedCurrency = widget.budget?.currency ?? 'LKR';
    _categories = [...?widget.budget?.categories];
  }

  @override
  void dispose() {
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final total = double.tryParse(_totalController.text.trim()) ?? 0;
    final allocated = _categories.fold<double>(
      0,
      (sum, item) => sum + item.allocatedAmount,
    );
    final result = await showDialog<BudgetCategory>(
      context: context,
      builder: (context) => _AddBudgetCategoryDialog(
        colorValue: _categoryColors[_categories.length % _categoryColors.length]
            .toARGB32(),
        maxAmount: (total - allocated).clamp(0, double.infinity).toDouble(),
      ),
    );
    if (result != null && mounted) {
      setState(() => _categories.add(result));
    }
  }

  Future<void> _editCategory(int index) async {
    final category = _categories[index];
    final total = double.tryParse(_totalController.text.trim()) ?? 0;
    final allocatedWithoutCurrent = _categories.fold<double>(
      0,
      (sum, item) => item.id == category.id ? sum : sum + item.allocatedAmount,
    );
    final result = await showDialog<BudgetCategory>(
      context: context,
      builder: (context) => _AddBudgetCategoryDialog(
        colorValue: category.colorValue,
        category: category,
        maxAmount: (total - allocatedWithoutCurrent)
            .clamp(0, double.infinity)
            .toDouble(),
      ),
    );
    if (result != null && mounted) {
      setState(() => _categories[index] = result);
    }
  }

  Future<void> _save() async {
    final total = double.tryParse(_totalController.text.trim());
    if (total == null || total <= 0 || _selectedCurrency.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.saveBudget(
        tripId: widget.trip.id,
        totalAmount: total,
        currency: _selectedCurrency,
        categories: _categories,
      );
      if (mounted) Navigator.pop(context, true);
    } on BudgetServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allocated = _categories.fold<double>(
      0,
      (sum, item) => sum + item.allocatedAmount,
    );
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * .78,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Budget Setup',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              TextField(
                controller: _totalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _budgetInputDecoration(
                  label: 'Total trip budget',
                  hint: '0.00',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: _budgetInputDecoration(
                  label: 'Currency',
                  hint: 'Select currency',
                ),
                items: _currencyOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.code,
                        child: Text('${option.symbol}  ${option.code}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCurrency = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Expense categories',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add category',
                    onPressed: _addCategory,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final item = _categories[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(item.colorValue),
                          radius: 7,
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '$_selectedCurrency ${item.allocatedAmount.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit category',
                              onPressed: () => _editCategory(index),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove category',
                              onPressed: () =>
                                  setState(() => _categories.removeAt(index)),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Allocated: ${allocated.toStringAsFixed(2)}'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_saving ? 'Saving...' : 'Save budget'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String currency;
  final double total;
  final double spent;
  final double remaining;
  final double ratio;
  const _OverviewCard({
    required this.currency,
    required this.total,
    required this.spent,
    required this.remaining,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1D4ED8), Color(0xFF0284C7)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2563EB).withValues(alpha: .2),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
            SizedBox(width: 9),
            Text(
              'Budget Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _AmountMetric(
                label: 'Total Budget',
                value: _money(currency, total),
                foregroundColor: Colors.white,
              ),
            ),
            Expanded(
              child: _AmountMetric(
                label: 'Spent',
                value: _money(currency, spent),
                foregroundColor: Colors.white,
              ),
            ),
            Expanded(
              child: _AmountMetric(
                label: 'Remaining',
                value: _money(currency, remaining),
                foregroundColor: remaining < 0
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFCFFAFE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        LinearProgressIndicator(
          value: ratio.clamp(0.0, 1.0).toDouble(),
          minHeight: 9,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.white24,
          color: ratio >= .8
              ? const Color(0xFFFCA5A5)
              : const Color(0xFF67E8F9),
        ),
        const SizedBox(height: 7),
        Text(
          '${(ratio * 100).clamp(0, 999).toStringAsFixed(1)}% used',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}

class _CategoryProgress extends StatelessWidget {
  final BudgetCategory category;
  final double spent;
  final String currency;
  const _CategoryProgress({
    required this.category,
    required this.spent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = category.allocatedAmount <= 0
        ? 0.0
        : spent / category.allocatedAmount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(category.name)),
              Text(
                '${_money(currency, spent)} / ${_money(currency, category.allocatedAmount)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0).toDouble(),
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            color: ratio >= .9 ? Colors.red : Color(category.colorValue),
            backgroundColor: const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  const _SectionCard({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 12),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _AmountMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color foregroundColor;
  const _AmountMetric({
    required this.label,
    required this.value,
    this.foregroundColor = const Color(0xFF111827),
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: TextStyle(
          color: foregroundColor.withValues(alpha: .72),
          fontSize: 11,
        ),
      ),
      const SizedBox(height: 5),
      FittedBox(
        child: Text(
          value,
          style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _BudgetAlert extends StatelessWidget {
  final String message;
  const _BudgetAlert({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      border: Border.all(color: const Color(0xFFFCA5A5)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _ExpenseActionIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExpenseActionIcon({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyBudget extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onSetup;
  const _EmptyBudget({required this.isAdmin, required this.onSetup});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 230,
            height: 175,
            child: CustomPaint(painter: _EmptyBudgetPainter()),
          ),
          const SizedBox(height: 18),
          const Text(
            'No trip budget yet',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'Set the total budget and allocate expense categories.'
                : 'A trip admin has not configured the budget yet.',
            textAlign: TextAlign.center,
          ),
          if (isAdmin) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onSetup,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Set up budget'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _EmptyBudgetPainter extends CustomPainter {
  const _EmptyBudgetPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cyan = Paint()
      ..color = const Color(0xFF06B6D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final paleBlue = Paint()
      ..color = const Color(0xFFDBEAFE)
      ..style = PaintingStyle.fill;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * .5, size.height * .46),
      size.width * .3,
      paleBlue,
    );

    final wallet = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .2,
        size.height * .35,
        size.width * .6,
        size.height * .43,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(wallet, white);
    canvas.drawRRect(wallet, blue);

    final clasp = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .57,
        size.height * .47,
        size.width * .27,
        size.height * .16,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(clasp, white);
    canvas.drawRRect(clasp, cyan);
    canvas.drawCircle(Offset(size.width * .68, size.height * .55), 4, blue);

    final plane = Path()
      ..moveTo(size.width * .18, size.height * .28)
      ..lineTo(size.width * .69, size.height * .1)
      ..lineTo(size.width * .57, size.height * .3)
      ..lineTo(size.width * .44, size.height * .29)
      ..lineTo(size.width * .36, size.height * .43)
      ..lineTo(size.width * .3, size.height * .44)
      ..lineTo(size.width * .32, size.height * .27)
      ..close();
    canvas.drawPath(plane, white);
    canvas.drawPath(plane, blue);

    canvas.drawCircle(Offset(size.width * .82, size.height * .25), 13, white);
    canvas.drawCircle(Offset(size.width * .82, size.height * .25), 13, cyan);
    final textPainter = TextPainter(
      text: const TextSpan(
        text: r'$',
        style: TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width * .82 - textPainter.width / 2,
        size.height * .25 - textPainter.height / 2,
      ),
    );

    canvas.drawLine(
      Offset(size.width * .28, size.height * .86),
      Offset(size.width * .72, size.height * .86),
      cyan,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptySection extends StatelessWidget {
  final String text;
  const _EmptySection({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: Text(text, style: const TextStyle(color: Color(0xFF6B7280))),
    ),
  );
}

class _BudgetContext {
  final TripModel trip;
  final List<AppUser> members;
  const _BudgetContext({required this.trip, required this.members});
}

class _PrivateDebtEntry {
  final String memberName;
  final double amount;
  final bool youOwe;

  const _PrivateDebtEntry({
    required this.memberName,
    required this.amount,
    required this.youOwe,
  });
}

const _categoryColors = [
  Color(0xFF2563EB),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
];

class _CurrencyOption {
  final String code;
  final String symbol;

  const _CurrencyOption(this.code, this.symbol);
}

const _currencyOptions = [
  _CurrencyOption('LKR', 'Rs'),
  _CurrencyOption('USD', r'$'),
  _CurrencyOption('EUR', '€'),
  _CurrencyOption('GBP', '£'),
  _CurrencyOption('JPY', '¥'),
  _CurrencyOption('INR', '₹'),
  _CurrencyOption('AUD', r'A$'),
  _CurrencyOption('CAD', r'C$'),
];

String _name(AppUser user) =>
    user.displayName.trim().isNotEmpty ? user.displayName : user.fullName;
String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((item) => item[0]).join().toUpperCase();
}

String _money(String currency, double value) =>
    '$currency ${value.toStringAsFixed(2)}';

InputDecoration _budgetInputDecoration({
  required String label,
  required String hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
    ),
  );
}

List<_PrivateDebtEntry> _privateDebtEntries({
  required List<TripExpense> expenses,
  required String? currentUid,
  required Map<String, AppUser> users,
}) {
  if (currentUid == null) return const [];
  final balances = <String, double>{};
  for (final expense in expenses.where((item) => !item.isGroupExpense)) {
    final payerUid = expense.paidByUid;
    if (payerUid == null) continue;
    for (final share in expense.shares.entries) {
      if (share.key == payerUid ||
          share.value <= 0 ||
          expense.settledParticipantIds.contains(share.key)) {
        continue;
      }
      if (share.key == currentUid) {
        balances[payerUid] = (balances[payerUid] ?? 0) - share.value;
      } else if (payerUid == currentUid) {
        balances[share.key] = (balances[share.key] ?? 0) + share.value;
      }
    }
  }
  return balances.entries.where((entry) => entry.value.abs() > .01).map((
    entry,
  ) {
    final user = users[entry.key];
    return _PrivateDebtEntry(
      memberName: user == null ? 'Trip member' : _name(user),
      amount: entry.value.abs(),
      youOwe: entry.value < 0,
    );
  }).toList();
}
