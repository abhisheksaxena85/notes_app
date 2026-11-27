import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/home/widgets/note_item_card.dart';
import 'package:notes_app/views/screens/home/widgets/create_task_modal.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_form_modal.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_item_card.dart';
import 'package:notes_app/views/screens/home/widgets/task_item_card.dart';
import 'package:notes_app/views/screens/note_details/note_details_screen.dart';
import 'package:notes_app/utils/date/date_keys.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  List<NoteItem> _getNotesForDate(List<NoteItem> allNotes, DateTime date) {
    return allNotes
        .where((note) => DateKeys.isOnDay(note.createdAt ?? note.updatedAt, date))
        .toList();
  }

  List<TaskItem> _getTasksForDate(List<TaskItem> allTasks, DateTime date) {
    return allTasks.where((task) {
      // dueDate is the wall-clock day the user picked: compared as is.
      if (task.dueDate != null && task.dueDate!.isNotEmpty) {
        final parts = task.dueDate!.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          return y == date.year && m == date.month && d == date.day;
        }
        return false;
      }
      // No due date: the local day it was created.
      return DateKeys.isOnDay(task.createdAt, date);
    }).toList();
  }

  List<ReminderItem> _getRemindersForDate(
    List<ReminderItem> allReminders,
    DateTime date,
  ) {
    return allReminders.where((reminder) {
      if (reminder.dueDate != null && reminder.dueDate!.isNotEmpty) {
        final parts = reminder.dueDate!.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          return y == date.year && m == date.month && d == date.day;
        }
      } else if (reminder.remindAt.isNotEmpty) {
        if (reminder.remindAt.length >= 10) {
          final parts = reminder.remindAt.substring(0, 10).split('-');
          if (parts.length == 3) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final d = int.tryParse(parts[2]);
            if (y == date.year && m == date.month && d == date.day) {
              return true;
            }
          }
        }
        final parsed = DateTime.tryParse(reminder.remindAt);
        if (parsed != null) {
          return parsed.year == date.year &&
              parsed.month == date.month &&
              parsed.day == date.day;
        }
      }
      return false;
    }).toList();
  }

  int _getActivityCountForDate(
    DateTime date,
    List<NoteItem> notes,
    List<TaskItem> tasks,
    List<ReminderItem> reminders,
  ) {
    return _getNotesForDate(notes, date).length +
        _getTasksForDate(tasks, date).length +
        _getRemindersForDate(reminders, date).length;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final homeState = ref.watch(homeController);
    final taskState = ref.watch(taskController);
    final reminderState = ref.watch(reminderController);

    final allNotes = homeState.value?.notesData?.data ?? [];
    final allTasks = taskState.value?.tasks ?? [];
    final allReminders = reminderState.value?.reminders ?? [];

    final selectedDayNotes = _getNotesForDate(allNotes, _selectedDate);
    final selectedDayTasks = _getTasksForDate(allTasks, _selectedDate);
    final selectedDayReminders = _getRemindersForDate(allReminders, _selectedDate);

    final totalItemsToday =
        selectedDayNotes.length + selectedDayTasks.length + selectedDayReminders.length;
    final grandTotalItems = allNotes.length + allTasks.length + allReminders.length;

    const monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    final currentMonthTitle =
        "${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}";

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: palette.accent,
          backgroundColor: palette.surface,
          onRefresh: () async {
            await Future.wait([
              ref.read(homeController.notifier).getAllNotes(),
              ref.read(taskController.notifier).refreshTasks(),
              ref.read(reminderController.notifier).refreshReminders(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.only(bottom: 90.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(top: 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "YOUR ACTIVITY",
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                          color: palette.muted,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              "Calendar",
                              style: GoogleFonts.inter(
                                fontSize: 31.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                                color: palette.ink,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "$grandTotalItems items total",
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Month Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: palette.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: palette.brightness == Brightness.dark ? 0.2 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      children: [
                        // Month Title + Nav Arrows
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentMonthTitle,
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: palette.ink,
                              ),
                            ),
                            Row(
                              children: [
                                _buildMonthNavBtn(
                                  Icons.chevron_left_rounded,
                                  _previousMonth,
                                  palette,
                                ),
                                SizedBox(width: 8.w),
                                _buildMonthNavBtn(
                                  Icons.chevron_right_rounded,
                                  _nextMonth,
                                  palette,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),

                        // Weekday Headers: M T W T F S S
                        Row(
                          children: const ["M", "T", "W", "T", "F", "S", "S"].map((d) {
                            return Expanded(
                              child: Center(
                                child: Text(
                                  d,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: palette.muted,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 10.h),

                        // Calendar Days Grid with Numerical Badges
                        _buildCalendarDaysGrid(
                          notes: allNotes,
                          tasks: allTasks,
                          reminders: allReminders,
                          palette: palette,
                        ),
                        SizedBox(height: 12.h),

                        // Legend Footnote
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: palette.accentSoft,
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: palette.accent.withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                "1",
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  color: palette.accent,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                "Badges show item count (Notes, Tasks, Reminders)",
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                  color: palette.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Weekly View Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Weekly view",
                        style: GoogleFonts.inter(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: palette.ink,
                        ),
                      ),
                      Text(
                        "${monthNames[_selectedDate.month - 1].substring(0, 3)} ${_selectedDate.year}",
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Week Strip with Numerical Badges
                SizedBox(
                  height: 78,
                  child: _buildWeekStrip(
                    notes: allNotes,
                    tasks: allTasks,
                    reminders: allReminders,
                    palette: palette,
                  ),
                ),
                SizedBox(height: 20.h),

                // Day Activity Heading
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Activity for ${_formatDayTitle(_selectedDate)}",
                          style: GoogleFonts.inter(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: palette.accentSoft,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          "$totalItemsToday ${totalItemsToday == 1 ? "item" : "items"}",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: palette.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Selected Day Items List (Notes + Tasks + Reminders)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: totalItemsToday == 0
                      ? Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: palette.line),
                          ),
                          child: Center(
                            child: Text(
                              "No activity recorded for this date.",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: palette.muted,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tasks for Date
                            if (selectedDayTasks.isNotEmpty) ...[
                              Text(
                                "TASKS (${selectedDayTasks.length})",
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: palette.muted,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              ...selectedDayTasks.map((task) {
                                return taskItemCard(
                                  context: context,
                                  task: task,
                                  onTap: task.taskId == null
                                      ? null
                                      : () => showCreateTaskModal(context, initial: task),
                                  onToggleComplete: (val) {
                                    if (task.taskId != null) {
                                      ref
                                          .read(taskController.notifier)
                                          .toggleTaskStatus(task.taskId!, val);
                                    }
                                  },
                                  onStatusSelected: (status) {
                                    if (task.taskId != null) {
                                      ref
                                          .read(taskController.notifier)
                                          .setTaskStatus(task.taskId!, status);
                                    }
                                  },
                                );
                              }),
                              SizedBox(height: 10.h),
                            ],

                            // Reminders for Date
                            if (selectedDayReminders.isNotEmpty) ...[
                              Text(
                                "REMINDERS (${selectedDayReminders.length})",
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: palette.muted,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              ...selectedDayReminders.map((reminder) {
                                return reminderItemCard(
                                  context: context,
                                  reminder: reminder,
                                  onTap: reminder.reminderId == null
                                      ? null
                                      : () => showReminderFormModal(context, initial: reminder),
                                  onStatusChange: (choice) {
                                    if (reminder.reminderId != null) {
                                      ref
                                          .read(reminderController.notifier)
                                          .applyChoice(reminder.reminderId!, choice);
                                    }
                                  },
                                  onStatusSelected: (choice) {
                                    if (reminder.reminderId != null) {
                                      ref
                                          .read(reminderController.notifier)
                                          .applyChoice(reminder.reminderId!, choice);
                                    }
                                  },
                                );
                              }),
                              SizedBox(height: 10.h),
                            ],

                            // Notes for Date
                            if (selectedDayNotes.isNotEmpty) ...[
                              Text(
                                "NOTES (${selectedDayNotes.length})",
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: palette.muted,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              ...selectedDayNotes.map((note) {
                                return noteItemCard(
                                  context: context,
                                  note: note,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            NoteDetailsScreen(noteId: note.noteId),
                                      ),
                                    );
                                  },
                                );
                              }),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavBtn(
    IconData icon,
    VoidCallback onTap,
    DaymarkPalette palette,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: palette.line),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18.sp,
            color: palette.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarDaysGrid({
    required List<NoteItem> notes,
    required List<TaskItem> tasks,
    required List<ReminderItem> reminders,
    required DaymarkPalette palette,
  }) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    final startWeekday = firstDayOfMonth.weekday;
    final prevMonthDaysCount = startWeekday - 1;

    final prevMonthLastDay =
        DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    final List<Widget> dayWidgets = [];

    // Preceding days from previous month
    for (int i = prevMonthDaysCount - 1; i >= 0; i--) {
      final dayNum = prevMonthLastDay - i;
      dayWidgets.add(
        _buildCalendarDayCell(
          dayText: "$dayNum",
          date: DateTime(_currentMonth.year, _currentMonth.month - 1, dayNum),
          activityCount: 0,
          isCurrentMonth: false,
          isSelected: false,
          onTap: null,
          palette: palette,
        ),
      );
    }

    // Days in current month
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, d);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final activityCount = _getActivityCountForDate(date, notes, tasks, reminders);

      dayWidgets.add(
        _buildCalendarDayCell(
          dayText: "$d",
          date: date,
          activityCount: activityCount,
          isCurrentMonth: true,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          palette: palette,
        ),
      );
    }

    // Trailing days for grid completeness (multiples of 7)
    final totalCells = ((dayWidgets.length + 6) ~/ 7) * 7;
    int nextDay = 1;
    while (dayWidgets.length < totalCells) {
      dayWidgets.add(
        _buildCalendarDayCell(
          dayText: "$nextDay",
          date: DateTime(_currentMonth.year, _currentMonth.month + 1, nextDay),
          activityCount: 0,
          isCurrentMonth: false,
          isSelected: false,
          onTap: null,
          palette: palette,
        ),
      );
      nextDay++;
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 4,
      childAspectRatio: 1.0,
      children: dayWidgets,
    );
  }

  Widget _buildCalendarDayCell({
    required String dayText,
    required DateTime date,
    required int activityCount,
    required bool isCurrentMonth,
    required bool isSelected,
    required VoidCallback? onTap,
    required DaymarkPalette palette,
  }) {
    final isDark = palette.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 36.r,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? palette.accent : palette.ink)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day Number
              Text(
                dayText,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? palette.background : palette.surface)
                      : (isCurrentMonth
                          ? palette.ink
                          : palette.muted.withValues(alpha: 0.4)),
                ),
              ),
              SizedBox(height: 2.h),

              // Numerical Count Badge (Replaces Dot)
              if (activityCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.25))
                        : palette.accentSoft,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : palette.accent.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    activityCount > 9 ? "9+" : "$activityCount",
                    style: GoogleFonts.inter(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? (isDark ? palette.background : palette.surface)
                          : palette.accent,
                    ),
                  ),
                )
              else
                SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekStrip({
    required List<NoteItem> notes,
    required List<TaskItem> tasks,
    required List<ReminderItem> reminders,
    required DaymarkPalette palette,
  }) {
    final startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    const dayNames = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: 7,
      itemBuilder: (context, index) {
        final date = startOfWeek.add(Duration(days: index));
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        final activityCount = _getActivityCountForDate(date, notes, tasks, reminders);

        return Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                if (date.month != _currentMonth.month) {
                  _currentMonth = DateTime(date.year, date.month, 1);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56,
              height: 74,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? palette.accentSoft : palette.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: isSelected ? palette.accent : palette.line,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayNames[index],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? palette.accent : palette.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${date.day}",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (activityCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.accent
                            : palette.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        activityCount > 9 ? "9+" : "$activityCount",
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? palette.surface
                              : palette.accent,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDayTitle(DateTime date) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${months[date.month - 1]} ${date.day}";
  }
}
