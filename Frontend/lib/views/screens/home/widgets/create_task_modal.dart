import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/network/dto/request/task/update_task_request_dto.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/home/widgets/item_delete.dart';
import 'package:notes_app/views/widgets/confirm_dialog.dart';
import 'package:notes_app/views/widgets/daymark_chip.dart';
import 'package:notes_app/views/widgets/labeled_field.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/segmented_control.dart';
import 'package:notes_app/views/widgets/sheet_scaffold.dart';

/// The task form, to create a task or (with [initial], FE-06) edit one.
/// Returns true when something was saved or deleted.
Future<bool?> showCreateTaskModal(BuildContext context, {TaskItem? initial}) {
  return showDaymarkSheet<bool>(
    context,
    // FIX-01: a drag would close it without the "Discard changes?" check;
    // back, a tap outside and the close button all ask.
    enableDrag: false,
    builder: (ctx) => TaskFormModal(initial: initial),
  );
}

class TaskFormModal extends ConsumerStatefulWidget {
  /// The task to edit; null to create one.
  final TaskItem? initial;

  const TaskFormModal({super.key, this.initial});

  @override
  ConsumerState<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends ConsumerState<TaskFormModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = "General";
  String _selectedPriority = "MEDIUM";
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  bool _isSaving = false;

  final List<String> _categories = ["General", "Work", "Personal", "Urgent"];
  final List<String> _priorities = ["LOW", "MEDIUM", "HIGH"];

  bool get _isEdit => widget.initial != null;

  /// FIX-01: the form's values when it opened, to tell if anything changed.
  late final Object _openedWith;
  Object get _values => (
        _titleController.text.trim(),
        _descController.text.trim(),
        _selectedDueDate,
        _selectedDueTime,
        _selectedCategory,
        _selectedPriority,
      );
  bool get _hasChanges => _values != _openedWith;
  bool _wasChanged = false;

  /// Typing doesn't rebuild the form; rebuild when "changed" flips so the
  /// back / tap-outside guard is current.
  void _onTextChanged() {
    if (_hasChanges != _wasChanged) setState(() => _wasChanged = _hasChanges);
  }

  Future<void> _onPopBlocked() async {
    if (!await confirmDiscardChanges(context)) return;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteTask() async {
    final deleted = await confirmAndDeleteTask(context, ref, widget.initial!);
    if (deleted && mounted) Navigator.pop(context, true);
  }

  @override
  void initState() {
    super.initState();
    _load(widget.initial);
    _openedWith = _values;
    _titleController.addListener(_onTextChanged);
    _descController.addListener(_onTextChanged);
  }

  void _load(TaskItem? initial) {
    if (initial == null) return;
    _titleController.text = initial.title;
    _descController.text = initial.description ?? '';
    final category = initial.category;
    if (category != null && category.trim().isNotEmpty) {
      _selectedCategory = category;
      if (!_categories.contains(category)) _categories.add(category);
    }
    final priority = initial.priority.toUpperCase();
    _selectedPriority = priority;
    if (!_priorities.contains(priority)) _priorities.add(priority);
    _selectedDueDate = _parseDate(initial.dueDate);
    _selectedDueTime = _parseTime(initial.dueTime);
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.length < 10) return null;
    return DateTime.tryParse(value.substring(0, 10));
  }

  static TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String? _formatDate(DateTime? date) => date == null
      ? null
      : "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  static String? _formatTime(TimeOfDay? time) => time == null
      ? null
      : "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDueDate ?? now;
    final firstDate = now.subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      // An edited task may be older than a year; keep its date pickable.
      firstDate: initialDate.isBefore(firstDate) ? initialDate : firstDate,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDueTime = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final dueDateStr = _formatDate(_selectedDueDate);
    final dueTimeStr = _formatTime(_selectedDueTime);
    final description = _descController.text.trim();

    try {
      final initial = widget.initial;
      if (initial != null) {
        await _saveEdit(initial, title, description, dueDateStr, dueTimeStr);
      } else {
        await ref.read(taskController.notifier).createTask(
              title: title,
              description: description.isNotEmpty ? description : null,
              dueDate: dueDateStr,
              dueTime: dueTimeStr,
              category: _selectedCategory,
              priority: _selectedPriority,
            );
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage(e))),
        );
      }
    }
  }

  /// Sends only the fields that changed; saved locally first and synced in
  /// the background (FE-02), so it works offline and before the first sync.
  Future<void> _saveEdit(
    TaskItem initial,
    String title,
    String description,
    String? dueDate,
    String? dueTime,
  ) async {
    String? changed(String? value, String? before) => value == before ? null : value;
    await ref.read(taskController.notifier).updateTask(
          UpdateTaskRequestDto(
            taskId: initial.taskId!,
            title: changed(title, initial.title),
            description: changed(description, initial.description ?? ''),
            dueDate: changed(dueDate, _formatDate(_parseDate(initial.dueDate))),
            dueTime: changed(dueTime, _formatTime(_parseTime(initial.dueTime))),
            category: changed(_selectedCategory, initial.category),
            priority: changed(_selectedPriority, initial.priority.toUpperCase()),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final fieldStyle = DaymarkText.custom(15, FontWeight.w400).copyWith(color: palette.ink);

    final sheet = SheetScaffold(
      title: _isEdit ? "Edit task" : "New task",
      actions: [
        if (_isEdit && widget.initial!.taskId != null)
          IconButton(
            tooltip: 'Delete',
            onPressed: _isSaving ? null : _deleteTask,
            icon: AppIcons.icon(AppIcons.delete, size: 20, color: palette.danger),
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
      ],
      footer: PrimaryButton(
        label: _isEdit ? "Save changes" : "Create task",
        loading: _isSaving,
        onPressed: _saveTask,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: "Title",
            child: TextField(
              controller: _titleController,
              style: fieldStyle,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: "What needs to be done?"),
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: "Notes",
            child: TextField(
              controller: _descController,
              minLines: 1,
              maxLines: 3,
              style: fieldStyle,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: "Add details (optional)"),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: LabeledField(
                  label: "Date",
                  child: PickerField(
                    icon: AppIcons.calendar,
                    value: _selectedDueDate == null
                        ? "Set date"
                        : DisplayFormat.fieldDate(_selectedDueDate!),
                    placeholder: _selectedDueDate == null,
                    onTap: _pickDate,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LabeledField(
                  label: "Time",
                  child: PickerField(
                    icon: AppIcons.clock,
                    value: _selectedDueTime == null
                        ? "Set time"
                        : DisplayFormat.time(_selectedDueTime!.hour, _selectedDueTime!.minute),
                    placeholder: _selectedDueTime == null,
                    onTap: _pickTime,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: "Priority",
            child: SegmentedControl<String>(
              height: 40,
              segments: {
                for (final pri in _priorities)
                  pri: pri[0] + pri.substring(1).toLowerCase(),
              },
              value: _selectedPriority,
              onChanged: (pri) => setState(() => _selectedPriority = pri),
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: "Category",
            child: CategoryChipRow(
              categories: _categories,
              selected: _selectedCategory,
              onSelected: (cat) => setState(() => _selectedCategory = cat),
            ),
          ),
        ],
      ),
    );
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopBlocked();
      },
      child: sheet,
    );
  }
}
