import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/network/dto/request/task/update_task_request_dto.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/viewmodel/controllers.dart';

/// The task form, to create a task or (with [initial], FE-06) edit one.
/// Returns true when something was saved.
Future<bool?> showCreateTaskModal(BuildContext context, {TaskItem? initial}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
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
                    _isEdit ? "Edit Task" : "New Task",
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: AppIcons.icon(AppIcons.close, color: palette.muted),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Task Title Input
              TextField(
                controller: _titleController,
                style: GoogleFonts.inter(fontSize: 15.sp, color: palette.ink),
                decoration: InputDecoration(
                  hintText: "What needs to be done?",
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
              SizedBox(height: 12.h),

              // Task Description Input
              TextField(
                controller: _descController,
                maxLines: 2,
                style: GoogleFonts.inter(fontSize: 14.sp, color: palette.ink),
                decoration: InputDecoration(
                  hintText: "Description or notes (optional)",
                  hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: palette.muted),
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

              // Due Date & Time Pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: AppIcons.icon(
                        AppIcons.calendar,
                        size: 16.sp,
                        color: palette.accent,
                      ),
                      label: Text(
                        _formatDate(_selectedDueDate) ?? "Set Due Date",
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
                      icon: AppIcons.icon(
                        AppIcons.clock,
                        size: 16.sp,
                        color: palette.accent,
                      ),
                      label: Text(
                        _formatTime(_selectedDueTime) ?? "Set Due Time",
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
                ],
              ),
              SizedBox(height: 16.h),

              // Category & Priority Chips
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
              SizedBox(height: 12.h),

              Text(
                "Priority",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 8.w,
                children: _priorities.map((pri) {
                  final isSelected = _selectedPriority == pri;
                  return ChoiceChip(
                    label: Text(pri),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedPriority = pri);
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
                  onPressed: _isSaving ? null : _saveTask,
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
                          _isEdit ? "Save Changes" : "Create Task",
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
