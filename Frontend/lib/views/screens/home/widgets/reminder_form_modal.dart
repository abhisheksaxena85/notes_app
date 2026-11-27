import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/screens/home/widgets/item_delete.dart';
import 'package:notes_app/views/widgets/confirm_dialog.dart';
import 'package:notes_app/views/widgets/daymark_chip.dart';
import 'package:notes_app/views/widgets/labeled_field.dart';
import 'package:notes_app/views/widgets/notification_permission_prompt.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/segmented_control.dart';
import 'package:notes_app/views/widgets/sheet_scaffold.dart';

/// REM-06: the reminder form, to create one or (with [initial]) edit it.
/// Returns true when something was saved or deleted.
Future<bool?> showReminderFormModal(
  BuildContext context, {
  ReminderItem? initial,
}) {
  return showDaymarkSheet<bool>(
    context,
    // FIX-01: a drag would close it without the "Discard changes?" check;
    // back, a tap outside and the close button all ask.
    enableDrag: false,
    builder: (ctx) => ReminderFormModal(initial: initial),
  );
}

/// The earliest time a reminder can be set to: one minute from now.
const minimumLead = Duration(minutes: 1);

/// Null if [date] at [time] is at least [minimumLead] after [now], otherwise
/// the inline error shown under the time field.
String? validateReminderTime({
  required DateTime date,
  required TimeOfDay time,
  required DateTime now,
}) {
  final at = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  if (at.isBefore(now.add(minimumLead))) {
    return 'Pick a time at least 1 minute from now.';
  }
  return null;
}

class ReminderFormModal extends ConsumerStatefulWidget {
  /// The reminder to edit; null to create one.
  final ReminderItem? initial;

  /// When a new reminder defaults to (now + 1 hour otherwise).
  final DateTime? initialDateTime;

  final DateTime Function() now;

  const ReminderFormModal({
    super.key,
    this.initial,
    this.initialDateTime,
    this.now = DateTime.now,
  });

  @override
  ConsumerState<ReminderFormModal> createState() => _ReminderFormModalState();
}

class _ReminderFormModalState extends ConsumerState<ReminderFormModal> {
  final _titleController = TextEditingController();
  String _selectedCategory = "General";
  String _selectedRepeat = "NONE";
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;
  String? _timeError;

  final List<String> _categories = ["General", "Work", "Personal", "Finance"];
  final List<String> _repeatOptions = ["NONE", "DAILY", "WEEKLY", "MONTHLY"];

  bool get _isEdit => widget.initial != null;

  /// The date and time the reminder had when the form opened (edit mode).
  DateTime? _initialAt;

  /// FIX-01: the form's values when it opened, to tell if anything changed.
  late final Object _openedWith;
  Object get _values => (
        _titleController.text.trim(),
        _selectedDate,
        _selectedTime,
        _selectedRepeat,
        _selectedCategory,
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

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final start = initial != null
        ? parseWallClock(initial.remindAt)
        : null;
    final defaultAt = widget.initialDateTime ?? widget.now().add(const Duration(hours: 1));
    final at = start == null
        ? defaultAt
        : DateTime(start.year, start.month, start.day, start.hour, start.minute);
    _initialAt = start == null ? null : at;
    _selectedDate = DateTime(at.year, at.month, at.day);
    _selectedTime = TimeOfDay(hour: at.hour, minute: at.minute);
    if (initial != null) {
      _titleController.text = initial.title;
      final category = initial.category;
      if (category != null && category.trim().isNotEmpty) {
        _selectedCategory = category;
        if (!_categories.contains(category)) _categories.add(category);
      }
      if (_repeatOptions.contains(initial.repeatInterval)) {
        _selectedRepeat = initial.repeatInterval;
      }
    }
    _openedWith = _values;
    _titleController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  DateTime get _selectedAt => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  bool get _timeChanged => !_isEdit || _selectedAt != _initialAt;

  Future<void> _pickDate() async {
    final now = widget.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      // An old reminder being edited may be in the past.
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _timeError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeError = null;
      });
    }
  }

  Future<void> _saveReminder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder title')),
      );
      return;
    }
    // A reminder can't be born overdue. Editing only the title of an old
    // reminder is still allowed.
    if (_timeChanged) {
      final error = validateReminderTime(date: _selectedDate, time: _selectedTime, now: widget.now());
      if (error != null) {
        setState(() => _timeError = error);
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    final dueDateStr =
        "${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final dueTimeStr =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";
    final remindAtStr = "${dueDateStr}T$dueTimeStr:00";

    try {
      final initial = widget.initial;
      if (initial != null) {
        await _saveEdit(initial, title, remindAtStr);
        if (mounted) Navigator.pop(context, true);
        return;
      }
      await ref.read(reminderController.notifier).createReminder(
            title: title,
            remindAt: remindAtStr,
            dueDate: dueDateStr,
            dueTime: dueTimeStr,
            category: _selectedCategory,
            repeatInterval: _selectedRepeat,
          );
      // REM-02: the first reminder is the moment to ask; it is saved whatever
      // the answer.
      if (mounted) {
        await maybeAskForNotifications(context, getIt<NotificationPermissionService>());
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

  /// Local first (works offline and before the first sync); the scheduler
  /// then moves the notification (REM-03).
  Future<void> _saveEdit(ReminderItem initial, String title, String remindAt) async {
    final repeatChanged = _selectedRepeat != initial.repeatInterval;
    // A new time or a new repeat re-anchors the series at the chosen time.
    final moveTime = _timeChanged || repeatChanged;
    await ref.read(reminderController.notifier).updateReminder(
          UpdateReminderRequestDto(
            reminderId: initial.reminderId!,
            title: title == initial.title ? null : title,
            remindAt: moveTime ? remindAt : null,
            category: _selectedCategory == initial.category ? null : _selectedCategory,
            repeatInterval: repeatChanged ? _selectedRepeat : null,
            // Moved to the future: it is pending again.
            status: _timeChanged && initial.status != 'PENDING' ? 'PENDING' : null,
          ),
        );
  }

  Future<void> _deleteReminder() async {
    final deleted = await confirmAndDeleteReminder(context, ref, widget.initial!);
    if (deleted && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final time = DisplayFormat.time(_selectedTime.hour, _selectedTime.minute);

    final sheet = SheetScaffold(
      title: _isEdit ? "Edit reminder" : "New reminder",
      actions: [
        if (_isEdit)
          IconButton(
            tooltip: 'Delete',
            onPressed: _isSaving ? null : _deleteReminder,
            icon: AppIcons.icon(AppIcons.delete, size: 20, color: palette.danger),
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
      ],
      footer: PrimaryButton(
        label: _isEdit ? "Save changes" : "Create reminder",
        loading: _isSaving,
        onPressed: _saveReminder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: "Title",
            child: TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: DaymarkText.custom(15, FontWeight.w400).copyWith(color: palette.ink),
              decoration: const InputDecoration(hintText: "Remind me to…"),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledField(
                  label: "Date",
                  child: PickerField(
                    icon: AppIcons.calendar,
                    value: DisplayFormat.fieldDate(_selectedDate),
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
                    value: time,
                    onTap: _pickTime,
                  ),
                ),
              ),
            ],
          ),
          if (_timeError != null) ...[
            const SizedBox(height: 6),
            Text(_timeError!, style: DaymarkText.meta.copyWith(color: palette.danger)),
          ],
          const SizedBox(height: 14),
          LabeledField(
            label: "Repeat",
            child: SegmentedControl<String>(
              height: 40,
              segments: {
                for (final repeat in _repeatOptions)
                  repeat: repeat[0] + repeat.substring(1).toLowerCase(),
              },
              value: _selectedRepeat,
              onChanged: (repeat) => setState(() => _selectedRepeat = repeat),
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
          const SizedBox(height: 16),
          // Info row: what the notification will offer.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcons.icon(AppIcons.reminder, size: 18, color: palette.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "You'll get a notification at $time. Mark it Done, Not done or Snooze right from it.",
                    style: DaymarkText.custom(13, FontWeight.w400, height: 1.45)
                        .copyWith(color: palette.inkSecondary),
                  ),
                ),
              ],
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
