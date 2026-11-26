import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/widgets/notification_permission_prompt.dart';

/// REM-06: the reminder form, to create one or (with [initial]) edit it.
/// Returns true when something was saved or deleted.
Future<bool?> showReminderFormModal(
  BuildContext context, {
  ReminderItem? initial,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
    final initial = widget.initial!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text("'${initial.title}' will be deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(reminderController.notifier).deleteReminder(initial.reminderId!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final isDark = palette.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: palette.line),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 38.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: palette.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? "Edit Reminder" : "New Reminder",
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isEdit)
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: _isSaving ? null : _deleteReminder,
                          icon: Icon(Icons.delete_outline_rounded, color: palette.danger),
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: palette.muted),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Reminder Title Input
              TextField(
                controller: _titleController,
                style: GoogleFonts.inter(fontSize: 15.sp, color: palette.ink),
                decoration: InputDecoration(
                  hintText: "Remind me to...",
                  hintStyle: GoogleFonts.inter(fontSize: 14.sp, color: palette.muted),
                  filled: true,
                  fillColor: palette.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: palette.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: palette.line),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Remind Date & Time Pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: Icon(
                        Icons.calendar_today_rounded,
                        size: 16.sp,
                        color: palette.accent,
                      ),
                      label: Text(
                        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: palette.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: palette.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: Icon(
                        Icons.access_time_rounded,
                        size: 16.sp,
                        color: palette.accent,
                      ),
                      label: Text(
                        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: palette.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _timeError != null ? palette.danger : palette.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
              if (_timeError != null) ...[
                SizedBox(height: 6.h),
                Text(
                  _timeError!,
                  style: GoogleFonts.inter(fontSize: 11.sp, color: palette.danger),
                ),
              ],
              SizedBox(height: 16.h),

              // Repeat Interval
              Text(
                "Repeat",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 8.w,
                children: _repeatOptions.map((repeat) {
                  final isSelected = _selectedRepeat == repeat;
                  return ChoiceChip(
                    label: Text(repeat),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedRepeat = repeat);
                    },
                    selectedColor: isDark ? palette.accent : palette.ink,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: isSelected
                          ? (isDark ? palette.background : palette.surface)
                          : palette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 14.h),

              // Category Chips
              Text(
                "Category",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 8.w,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: isDark ? palette.accent : palette.ink,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: isSelected
                          ? (isDark ? palette.background : palette.surface)
                          : palette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? palette.accent : palette.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? palette.background : palette.surface,
                          ),
                        )
                      : Text(
                          _isEdit ? "Save Changes" : "Create Reminder",
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? palette.background : palette.surface,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}
