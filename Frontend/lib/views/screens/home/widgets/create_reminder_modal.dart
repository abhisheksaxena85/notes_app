import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/controllers.dart';

Future<bool?> showCreateReminderModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CreateReminderModalView(),
  );
}

class _CreateReminderModalView extends ConsumerStatefulWidget {
  const _CreateReminderModalView();

  @override
  ConsumerState<_CreateReminderModalView> createState() =>
      _CreateReminderModalViewState();
}

class _CreateReminderModalViewState
    extends ConsumerState<_CreateReminderModalView> {
  final _titleController = TextEditingController();
  String _selectedCategory = "General";
  String _selectedRepeat = "NONE";
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );
  bool _isSaving = false;

  final List<String> _categories = ["General", "Work", "Personal", "Finance"];
  final List<String> _repeatOptions = ["NONE", "DAILY", "WEEKLY", "MONTHLY"];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
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

    setState(() {
      _isSaving = true;
    });

    final dueDateStr =
        "${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final dueTimeStr =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";
    final remindAtStr = "${dueDateStr}T$dueTimeStr:00";

    try {
      await ref.read(reminderController.notifier).createReminder(
            title: title,
            remindAt: remindAtStr,
            dueDate: dueDateStr,
            dueTime: dueTimeStr,
            category: _selectedCategory,
            repeatInterval: _selectedRepeat,
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
          SnackBar(content: Text('Failed to create reminder: $e')),
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
                    "New Reminder",
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
                          "Create Reminder",
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
