import 'package:flutter/material.dart';

import '../models/personal_task.dart';
import '../services/task_service.dart';

const _taskBlue = Color(0xFF2563EB);
const _taskBlueDark = Color(0xFF1D4ED8);

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final TaskService _taskService;

  @override
  void initState() {
    super.initState();
    _taskService = TaskService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<PersonalTask>>(
              stream: _taskService.watchMyTasks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorState(message: _errorMessage(snapshot.error));
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _taskBlue),
                  );
                }
                return _buildContent(snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_taskBlue, _taskBlueDark]),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: IconButton(
                  tooltip: 'Add task',
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _showTaskEditor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Manage your personal tasks',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<PersonalTask> tasks) {
    final pending = tasks.where((task) => !task.isCompleted).toList();
    final completed = tasks.where((task) => task.isCompleted).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _TaskSummary(total: tasks.length, completed: completed.length),
          const SizedBox(height: 24),
          if (tasks.isEmpty)
            _EmptyTasks(onAdd: () => _showTaskEditor())
          else ...[
            _sectionTitle('Pending Tasks', pending.length),
            const SizedBox(height: 12),
            if (pending.isEmpty)
              const _AllDoneCard()
            else
              ...pending.map(_taskCard),
            if (completed.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle('Completed Tasks', completed.length),
              const SizedBox(height: 12),
              ...completed.map(_taskCard),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text(
          '$count ${count == 1 ? 'task' : 'tasks'}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _taskCard(PersonalTask task) {
    final completed = task.isCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFEAF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Checkbox(
            value: completed,
            activeColor: _taskBlue,
            shape: const CircleBorder(),
            onChanged: (value) =>
                _run(() => _taskService.setCompleted(task, value ?? false)),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: completed
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _dueDateLabel(task.dueDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      task.priority,
                      style: TextStyle(
                        color: completed
                            ? Colors.grey
                            : _priorityColor(task.priority),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Task actions',
            onSelected: (value) {
              switch (value) {
                case 'pending':
                  _run(() => _taskService.setCompleted(task, false));
                  break;
                case 'edit':
                  _showTaskEditor(task);
                  break;
                case 'delete':
                  _confirmDelete(task);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (completed)
                const PopupMenuItem(
                  value: 'pending',
                  child: Row(
                    children: [
                      Icon(Icons.undo_rounded, color: _taskBlue),
                      SizedBox(width: 10),
                      Text('Move to pending'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showTaskEditor([PersonalTask? task]) async {
    final controller = TextEditingController(text: task?.title);
    var selectedDate = task?.dueDate ?? DateTime.now();
    var selectedPriority = task?.priority ?? 'medium';
    final draft = await showDialog<_TaskDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task == null ? 'Add task' : 'Edit task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'What do you need to do?',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _taskBlue, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_today_outlined,
                    color: _taskBlue,
                  ),
                  title: const Text('Due date'),
                  subtitle: Text(_formatDate(selectedDate)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 10),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(Icons.flag_outlined, color: _taskBlue),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedPriority = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _taskBlue),
              onPressed: () {
                final title = controller.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  _TaskDraft(
                    title: title,
                    dueDate: selectedDate,
                    priority: selectedPriority,
                  ),
                );
              },
              child: Text(task == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (draft == null || !mounted) return;
    await _run(
      () => task == null
          ? _taskService.addTask(
              title: draft.title,
              dueDate: draft.dueDate,
              priority: draft.priority,
            )
          : _taskService.updateTask(
              task: task,
              title: draft.title,
              dueDate: draft.dueDate,
              priority: draft.priority,
            ),
    );
  }

  Future<void> _confirmDelete(PersonalTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(() => _taskService.deleteTask(task));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on TaskServiceException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Something went wrong. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object? error) {
    return error is TaskServiceException
        ? error.message
        : 'Unable to load your tasks.';
  }
}

class _TaskSummary extends StatelessWidget {
  final int total;
  final int completed;

  const _TaskSummary({required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    final pending = total - completed;
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(value: '$total', label: 'Total Tasks'),
              _StatItem(value: '$pending', label: 'Pending', color: _taskBlue),
              _StatItem(
                value: '$completed',
                label: 'Completed',
                color: const Color(0xFF16A34A),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: _taskBlue,
              backgroundColor: const Color(0xFFDBEAFE),
            ),
          ),
          const SizedBox(height: 10),
          Text('${(progress * 100).round()}% complete'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    this.color = const Color(0xFF111827),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyTasks({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const _TaskIllustration(),
          const SizedBox(height: 12),
          const Text(
            'No tasks yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first personal task and keep your plans on track.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: _taskBlue,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add a task'),
          ),
        ],
      ),
    );
  }
}

class _TaskIllustration extends StatelessWidget {
  const _TaskIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
          ),
          Transform.rotate(
            angle: -.06,
            child: Container(
              width: 112,
              height: 138,
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _taskBlue.withValues(alpha: .14),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  _IllustrationLine(checked: true, width: 52),
                  SizedBox(height: 15),
                  _IllustrationLine(width: 61),
                  SizedBox(height: 15),
                  _IllustrationLine(width: 45),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            child: Container(
              width: 48,
              height: 22,
              decoration: BoxDecoration(
                color: _taskBlue,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const Positioned(
            right: 12,
            top: 45,
            child: Icon(Icons.auto_awesome, color: Color(0xFF60A5FA), size: 28),
          ),
          const Positioned(
            left: 10,
            bottom: 30,
            child: Icon(Icons.check_circle, color: _taskBlue, size: 34),
          ),
        ],
      ),
    );
  }
}

class _IllustrationLine extends StatelessWidget {
  final bool checked;
  final double width;

  const _IllustrationLine({this.checked = false, required this.width});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 17,
          color: checked ? _taskBlue : const Color(0xFF93C5FD),
        ),
        const SizedBox(width: 8),
        Container(
          width: width,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFFBFDBFE),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.task_alt_rounded, color: _taskBlue),
          SizedBox(width: 12),
          Text('All tasks are completed.'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: _taskBlue, size: 52),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _TaskDraft {
  final String title;
  final DateTime dueDate;
  final String priority;

  const _TaskDraft({
    required this.title,
    required this.dueDate,
    required this.priority,
  });
}

String _dueDateLabel(DateTime? date) {
  return date == null ? 'No due date' : 'Due ${_formatDate(date)}';
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

Color _priorityColor(String priority) {
  return switch (priority) {
    'high' => const Color(0xFFDC2626),
    'low' => const Color(0xFF16A34A),
    _ => const Color(0xFF2563EB),
  };
}