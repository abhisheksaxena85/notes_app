import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/controllers.dart';

Future<bool?> showCreateTaskModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CreateTaskModalView(),
  );
}

class _CreateTaskModalView extends ConsumerStatefulWidget {
  const _CreateTaskModalView();

  @override
  ConsumerState<_CreateTaskModalView> createState() => _CreateTaskModalViewState();
}

class _CreateTaskModalViewState extends ConsumerState<_CreateTaskModalView> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = "General";
  String _selectedPriority = "MEDIUM";
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  bool _isSaving = false;

  final List<String> _categories = ["General", "Work", "Personal", "Urgent"];
  final List<String> _priorities = ["LOW", "MEDIUM", "HIGH"];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
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

    String? dueDateStr;
    if (_selectedDueDate != null) {
      dueDateStr =
          "${_selectedDueDate!.year.toString().padLeft(4, '0')}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}";
    }

    String? dueTimeStr;
    if (_selectedDueTime != null) {
      dueTimeStr =
          "${_selectedDueTime!.hour.toString().padLeft(2, '0')}:${_selectedDueTime!.minute.toString().padLeft(2, '0')}";
    }

    try {
      await ref.read(taskController.notifier).createTask(
            title: title,
            description: _descController.text.trim().isNotEmpty
                ? _descController.text.trim()
                : null,
            dueDate: dueDateStr,
            dueTime: dueTimeStr,
            category: _selectedCategory,
            priority: _selectedPriority,
          );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: $e')),
        );
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
                    "New Task",
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: palette.muted),
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
                      icon: Icon(
                        Icons.calendar_today_rounded,
                        size: 16.sp,
                        color: palette.accent,
                      ),
                      label: Text(
                        _selectedDueDate == null
                            ? "Set Due Date"
                            : "${_selectedDueDate!.year}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}",
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
                        _selectedDueTime == null
                            ? "Set Due Time"
                            : "${_selectedDueTime!.hour.toString().padLeft(2, '0')}:${_selectedDueTime!.minute.toString().padLeft(2, '0')}",
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
                          "Create Task",
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
