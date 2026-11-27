import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/data/network/dto/response/item_status.dart';
import 'package:notes_app/views/screens/home/widgets/item_status_sheet.dart';
import 'package:notes_app/views/screens/home/widgets/create_task_modal.dart';
import 'package:notes_app/views/screens/home/widgets/item_delete.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_form_modal.dart';
import 'package:notes_app/views/screens/note_details/note_details_screen.dart';
import 'package:notes_app/utils/date/date_keys.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/screens/calendar/widgets/calendar_loading_widget.dart';
import 'package:notes_app/views/widgets/daymark_card.dart';
import 'package:notes_app/views/widgets/skeleton/skeleton.dart';
import 'package:notes_app/views/widgets/icon_tile.dart';
import 'package:notes_app/views/widgets/segmented_control.dart';

enum CalendarMode { month, week }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  CalendarMode _mode = CalendarMode.month;

  /// True during the first load (set in build).
  bool _loading = false;

  Widget _maybeShimmer(Widget child) => _loading ? Shimmer(child: child) : child;

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

  /// Week view: move the selection a week and keep the month in step.
  void _shiftWeek(int weeks) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + 7 * weeks,
      );
      _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    });
  }

  void _select(DateTime date) {
    setState(() {
      _selectedDate = date;
      if (date.month != _currentMonth.month || date.year != _currentMonth.year) {
        _currentMonth = DateTime(date.year, date.month, 1);
      }
    });
  }

  /// Monday of the week holding [date].
  static DateTime _weekStart(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

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

    int countFor(DateTime date) =>
        _getActivityCountForDate(date, allNotes, allTasks, allReminders);

    // First load: badges, the count and the day list shimmer; the grid
    // itself needs no data.
    bool firstLoad(AsyncValue<Object?> value) => value.isLoading && !value.hasValue;
    _loading = firstLoad(homeState) || firstLoad(taskState) || firstLoad(reminderState);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
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
          child: _maybeShimmer(ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // Title + Month / Week
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Calendar",
                      style: DaymarkText.title.copyWith(color: palette.ink),
                    ),
                  ),
                  SegmentedControl<CalendarMode>(
                    expand: false,
                    height: 34,
                    segments: const {
                      CalendarMode.month: 'Month',
                      CalendarMode.week: 'Week',
                    },
                    value: _mode,
                    onChanged: (mode) => setState(() {
                      _mode = mode;
                      if (mode == CalendarMode.month) {
                        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DaymarkCard(
                radius: 20,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: _mode == CalendarMode.month
                    ? _buildMonth(palette, countFor)
                    : _buildWeek(palette, countFor),
              ),
              const SizedBox(height: 22),
              // Selected day
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DisplayFormat.longDate(_selectedDate),
                      style: DaymarkText.section.copyWith(color: palette.ink),
                    ),
                  ),
                  if (_loading)
                    const CalendarCountSkeleton()
                  else
                    Text(
                      "$totalItemsToday ${totalItemsToday == 1 ? "item" : "items"}",
                      style: DaymarkText.meta.copyWith(color: palette.muted),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_loading)
                const CalendarDayListSkeleton()
              else
                _buildDayList(
                  palette: palette,
                  tasks: selectedDayTasks,
                  reminders: selectedDayReminders,
                  notes: selectedDayNotes,
                ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _monthHeader(DaymarkPalette palette, String title, VoidCallback onPrev, VoidCallback onNext) {
    return Row(
      children: [
        _navButton(AppIcons.back, 'Previous', onPrev, palette),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: DaymarkText.custom(15, FontWeight.w600).copyWith(color: palette.ink),
          ),
        ),
        _navButton(AppIcons.forward, 'Next', onNext, palette),
      ],
    );
  }

  Widget _weekdayRow(DaymarkPalette palette) {
    return Row(
      children: [
        for (final d in const ["M", "T", "W", "T", "F", "S", "S"])
          Expanded(
            child: Center(
              child: Text(
                d,
                style: DaymarkText.custom(11.5, FontWeight.w500).copyWith(color: palette.muted),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonth(DaymarkPalette palette, int Function(DateTime) countFor) {
    return Column(
      children: [
        _monthHeader(palette, DisplayFormat.monthYear(_currentMonth), _previousMonth, _nextMonth),
        const SizedBox(height: 6),
        _weekdayRow(palette),
        const SizedBox(height: 6),
        _buildCalendarDaysGrid(palette: palette, countFor: countFor),
      ],
    );
  }

  Widget _buildWeek(DaymarkPalette palette, int Function(DateTime) countFor) {
    final start = _weekStart(_selectedDate);
    final end = DateTime(start.year, start.month, start.day + 6);
    final title = start.month == end.month
        ? '${start.day} – ${DisplayFormat.shortDate(end)} ${end.year}'
        : '${DisplayFormat.shortDate(start)} – ${DisplayFormat.shortDate(end)} ${end.year}';
    return Column(
      children: [
        _monthHeader(palette, title, () => _shiftWeek(-1), () => _shiftWeek(1)),
        const SizedBox(height: 6),
        _weekdayRow(palette),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: _buildCalendarDayCell(
                  date: DateTime(start.year, start.month, start.day + i),
                  activityCount: countFor(DateTime(start.year, start.month, start.day + i)),
                  isCurrentMonth: true,
                  palette: palette,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _navButton(String icon, String tooltip, VoidCallback onTap, DaymarkPalette palette) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: AppIcons.icon(icon, size: 20, color: palette.inkSecondary),
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildCalendarDaysGrid({
    required DaymarkPalette palette,
    required int Function(DateTime) countFor,
  }) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final leading = firstDayOfMonth.weekday - 1;
    final cells = <Widget>[];
    // Days of the previous month that fill the first row.
    for (int i = leading; i > 0; i--) {
      cells.add(_buildCalendarDayCell(
        date: DateTime(_currentMonth.year, _currentMonth.month, 1 - i),
        activityCount: 0,
        isCurrentMonth: false,
        palette: palette,
      ));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, d);
      cells.add(_buildCalendarDayCell(
        date: date,
        activityCount: countFor(date),
        isCurrentMonth: true,
        palette: palette,
      ));
    }
    // Days of the next month that complete the last row.
    var next = 1;
    while (cells.length % 7 != 0) {
      cells.add(_buildCalendarDayCell(
        date: DateTime(_currentMonth.year, _currentMonth.month + 1, next++),
        activityCount: 0,
        isCurrentMonth: false,
        palette: palette,
      ));
    }
    return Column(
      children: [
        for (var row = 0; row < cells.length; row += 7)
          Row(children: [for (final cell in cells.sublist(row, row + 7)) Expanded(child: cell)]),
      ],
    );
  }

  /// A 42 px day cell: the number in a 30 px circle (accent fill when
  /// selected) with the item count badge below it.
  Widget _buildCalendarDayCell({
    required DateTime date,
    required int activityCount,
    required bool isCurrentMonth,
    required DaymarkPalette palette,
  }) {
    final isSelected = DisplayFormat.sameDay(date, _selectedDate);
    final isToday = DisplayFormat.sameDay(date, DateTime.now());
    final Color numberColor;
    if (!isCurrentMonth) {
      numberColor = palette.disabled;
    } else if (isSelected) {
      numberColor = palette.onAccent;
    } else if (isToday) {
      numberColor = palette.accent;
    } else {
      numberColor = palette.ink;
    }

    final cell = SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected && isCurrentMonth ? palette.accent : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                "${date.day}",
                style: DaymarkText.custom(
                  13.5,
                  isSelected || isToday ? FontWeight.w600 : FontWeight.w500,
                ).copyWith(color: numberColor),
              ),
            ),
          ),
          if (isCurrentMonth && _loading)
            const Positioned(top: 34, child: CalendarBadgeSkeleton())
          else if (isCurrentMonth && activityCount > 0)
            Positioned(
              top: 31,
              child: Container(
                height: 13,
                constraints: const BoxConstraints(minWidth: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? palette.accent : palette.accentSoft,
                  borderRadius: BorderRadius.circular(6.5),
                  border: isSelected ? Border.all(color: palette.surface, width: 1) : null,
                ),
                child: Text(
                  "$activityCount",
                  style: DaymarkText.custom(9.5, FontWeight.w600, height: 1).copyWith(
                    color: isSelected ? palette.onAccent : palette.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!isCurrentMonth) return cell;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${DisplayFormat.longDate(date)}, $activityCount ${activityCount == 1 ? 'item' : 'items'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(date),
        child: cell,
      ),
    );
  }

  /// The selected day's items in one grouped card with dividers.
  Widget _buildDayList({
    required DaymarkPalette palette,
    required List<TaskItem> tasks,
    required List<ReminderItem> reminders,
    required List<NoteItem> notes,
  }) {
    if (tasks.isEmpty && reminders.isEmpty && notes.isEmpty) {
      return DaymarkCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: Text(
            "Nothing on this day.",
            style: DaymarkText.preview.copyWith(color: palette.muted),
          ),
        ),
      );
    }

    final rows = <Widget>[
      for (final task in tasks) _taskRow(palette, task),
      for (final reminder in reminders) _reminderRow(palette, reminder),
      for (final note in notes) _noteRow(palette, note),
    ];
    return DaymarkCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: 60, color: palette.divider),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _dayRow({
    required DaymarkPalette palette,
    required String icon,
    required Color tileFill,
    required Color tileColor,
    required String title,
    required String meta,
    bool done = false,
    String? tileLabel,
    VoidCallback? onTileTap,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final tile = IconTile(
      icon: icon,
      size: 34,
      radius: 10,
      iconSize: 18,
      background: tileFill,
      color: tileColor,
    );
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
        child: Row(
          children: [
            onTileTap == null
                ? Padding(padding: const EdgeInsets.all(5), child: tile)
                : Semantics(
                    button: true,
                    label: tileLabel,
                    child: GestureDetector(
                      onTap: onTileTap,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(padding: const EdgeInsets.all(5), child: tile),
                    ),
                  ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DaymarkText.custom(14.5, FontWeight.w500).copyWith(
                      color: done ? palette.muted : palette.ink,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: palette.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(meta, style: DaymarkText.meta.copyWith(color: palette.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskRow(DaymarkPalette palette, TaskItem task) {
    final status = task.effectiveStatus();
    final completed = status == 'COMPLETED';
    final missed = status == 'MISSED' || status == 'REJECTED';
    final time = (task.dueTime?.isNotEmpty ?? false) ? ' · ${DisplayFormat.clock(task.dueTime!)}' : '';
    final label = missed ? ' · ${status[0]}${status.substring(1).toLowerCase()}' : '';
    return _dayRow(
      palette: palette,
      icon: completed ? AppIcons.check : AppIcons.task,
      tileFill: completed ? palette.successSoft : (missed ? palette.dangerSoft : palette.accentSoft),
      tileColor: completed ? palette.success : (missed ? palette.danger : palette.accent),
      title: task.title.trim().isNotEmpty ? task.title : "Untitled Task",
      meta: 'Task$time$label',
      done: completed,
      tileLabel: completed ? 'Mark as not done' : 'Mark as done',
      onTileTap: task.taskId == null
          ? null
          : () => ref.read(taskController.notifier).toggleTaskStatus(task.taskId!, !completed),
      onTap: task.taskId == null ? null : () => showCreateTaskModal(context, initial: task),
      onLongPress: task.taskId == null
          ? null
          : () async {
              final selected = await showItemStatusSheet(
                context,
                currentStatus: task.status,
                canDelete: true,
              );
              if (!mounted) return;
              if (selected == deleteItemChoice) {
                await confirmAndDeleteTask(context, ref, task);
              } else if (selected != null) {
                ref.read(taskController.notifier).setTaskStatus(task.taskId!, selected);
              }
            },
    );
  }

  Widget _reminderRow(DaymarkPalette palette, ReminderItem reminder) {
    final status = reminder.effectiveStatus();
    final completed = status == 'COMPLETED';
    final missed = status == 'MISSED' || status == 'REJECTED';
    final repeating = reminder.repeatInterval != 'NONE';
    final time = (reminder.dueTime?.isNotEmpty ?? false)
        ? ' · ${DisplayFormat.clock(reminder.dueTime!)}'
        : '';
    final label = missed ? ' · ${status[0]}${status.substring(1).toLowerCase()}' : '';
    void apply(String choice) {
      if (reminder.reminderId != null) {
        ref.read(reminderController.notifier).applyChoice(reminder.reminderId!, choice);
      }
    }

    return _dayRow(
      palette: palette,
      icon: completed ? AppIcons.check : AppIcons.reminder,
      tileFill: completed ? palette.successSoft : (missed ? palette.dangerSoft : palette.accentSoft),
      tileColor: completed ? palette.success : (missed ? palette.danger : palette.accent),
      title: reminder.title.trim().isNotEmpty ? reminder.title : "Untitled Reminder",
      meta: 'Reminder$time$label',
      done: completed,
      tileLabel: completed ? 'Mark as not done' : 'Mark as done',
      // REM-05: a pending repeat is done for this occurrence only.
      onTileTap: reminder.reminderId == null
          ? null
          : () => apply(repeating && !completed
              ? RepeatingChoice.doneToday
              : (completed ? 'PENDING' : 'COMPLETED')),
      onTap: reminder.reminderId == null
          ? null
          : () => showReminderFormModal(context, initial: reminder),
      onLongPress: reminder.reminderId == null
          ? null
          : () async {
              final selected = await showItemStatusSheet(
                context,
                currentStatus: reminder.status,
                repeating: repeating && reminder.status == 'PENDING',
                canDelete: true,
              );
              if (!mounted) return;
              if (selected == deleteItemChoice) {
                await confirmAndDeleteReminder(context, ref, reminder);
              } else if (selected != null) {
                apply(selected);
              }
            },
    );
  }

  Widget _noteRow(DaymarkPalette palette, NoteItem note) {
    final created = DateKeys.instant(note.createdAt ?? note.updatedAt);
    final time = created == null ? '' : ' · ${DisplayFormat.time(created.hour, created.minute)}';
    return _dayRow(
      palette: palette,
      icon: AppIcons.note,
      tileFill: palette.tagFill,
      tileColor: palette.inkSecondary,
      title: (note.title?.trim().isNotEmpty ?? false) ? note.title! : "Untitled Note",
      meta: 'Note$time',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteDetailsScreen(noteId: note.noteId)),
        );
      },
    );
  }
}
