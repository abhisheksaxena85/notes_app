import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/viewmodel/home/home_viewmodel.dart';
import 'package:notes_app/views/screens/home/widgets/create_reminder_modal.dart';
import 'package:notes_app/views/screens/home/widgets/create_task_modal.dart';
import 'package:notes_app/views/screens/home/widgets/note_item_card.dart';
import 'package:notes_app/views/screens/home/widgets/notes_error_widget.dart';
import 'package:notes_app/views/screens/home/widgets/notes_floating_action_button.dart';
import 'package:notes_app/views/screens/home/widgets/notes_header_widget.dart';
import 'package:notes_app/views/screens/home/widgets/notes_loading_widget.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_item_card.dart';
import 'package:notes_app/views/screens/home/widgets/sync_failures_banner.dart';
import 'package:notes_app/views/screens/home/widgets/task_item_card.dart';
import 'package:notes_app/views/screens/note_details/note_details_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = "All"; // "All", "Notes", "Tasks", "Reminders"
  String _searchQuery = "";
  bool _isSpeedDialOpen = false;

  final List<String> _filters = ["All", "Notes", "Tasks", "Reminders"];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll(
    BuildContext context,
    HomeViewmodel notifier,
  ) async {
    try {
      await Future.wait([
        notifier.getAllNotes(),
        ref.read(taskController.notifier).refreshTasks(),
        ref.read(reminderController.notifier).refreshReminders(),
      ]);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refresh items: $error')),
      );
    }
  }

  List<NoteItem> _filterNotes(List<NoteItem> rawNotes) {
    var list = List<NoteItem>.from(rawNotes);
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((n) {
        final title = (n.title ?? "").toLowerCase();
        final content = (n.content ?? "").toLowerCase();
        final cat = (n.category ?? "").toLowerCase();
        return title.contains(q) || content.contains(q) || cat.contains(q);
      }).toList();
    }
    // Sort pinned first
    list.sort((a, b) {
      final isPinA = a.pinned == true;
      final isPinB = b.pinned == true;
      if (isPinA && !isPinB) return -1;
      if (!isPinA && isPinB) return 1;
      return (b.noteId ?? 0).compareTo(a.noteId ?? 0);
    });
    return list;
  }

  List<TaskItem> _filterTasks(List<TaskItem> rawTasks) {
    var list = List<TaskItem>.from(rawTasks);
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((t) {
        final title = t.title.toLowerCase();
        final desc = (t.description ?? "").toLowerCase();
        final cat = (t.category ?? "").toLowerCase();
        return title.contains(q) || desc.contains(q) || cat.contains(q);
      }).toList();
    }
    // Sort uncompleted first
    list.sort((a, b) {
      final doneA = a.isCompleted || a.status == 'COMPLETED';
      final doneB = b.isCompleted || b.status == 'COMPLETED';
      if (!doneA && doneB) return -1;
      if (doneA && !doneB) return 1;
      return (b.taskId ?? 0).compareTo(a.taskId ?? 0);
    });
    return list;
  }

  List<ReminderItem> _filterReminders(List<ReminderItem> rawReminders) {
    var list = List<ReminderItem>.from(rawReminders);
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((r) {
        final title = r.title.toLowerCase();
        final cat = (r.category ?? "").toLowerCase();
        return title.contains(q) || cat.contains(q);
      }).toList();
    }
    // Sort pending first
    list.sort((a, b) {
      final doneA = a.status == 'COMPLETED';
      final doneB = b.status == 'COMPLETED';
      if (!doneA && doneB) return -1;
      if (doneA && !doneB) return 1;
      return (b.reminderId ?? 0).compareTo(a.reminderId ?? 0);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final homeState = ref.watch(homeController);
    final taskState = ref.watch(taskController);
    final reminderState = ref.watch(reminderController);

    final homeNotifier = ref.read(homeController.notifier);
    final profileState = ref.watch(profileController);
    final userName = profileState.value?.profileData?.data?.name;

    final allNotes = homeState.value?.notesData?.data ?? [];
    final allTasks = taskState.value?.tasks ?? [];
    final allReminders = reminderState.value?.reminders ?? [];

    final displayedNotes = _filterNotes(allNotes);
    final displayedTasks = _filterTasks(allTasks);
    final displayedReminders = _filterReminders(allReminders);

    final int totalActiveItems = allNotes.length + allTasks.length + allReminders.length;

    return Scaffold(
      backgroundColor: palette.background,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 12.h, right: 4.w),
        child: AddSpeedDialFab(
          isOpen: _isSpeedDialOpen,
          onOpenChanged: (val) {
            setState(() {
              _isSpeedDialOpen = val;
            });
          },
          onNewNote: () async {
            setState(() => _isSpeedDialOpen = false);
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NoteDetailsScreen(),
              ),
            );
            if (result == true && context.mounted) {
              _refreshAll(context, homeNotifier);
            }
          },
          onNewTask: () async {
            setState(() => _isSpeedDialOpen = false);
            final res = await showCreateTaskModal(context);
            if (res == true && context.mounted) {
              _refreshAll(context, homeNotifier);
            }
          },
          onNewReminder: () async {
            setState(() => _isSpeedDialOpen = false);
            final res = await showCreateReminderModal(context);
            if (res == true && context.mounted) {
              _refreshAll(context, homeNotifier);
            }
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                notesHeaderWidget(
                  context: context,
                  noteCount: totalActiveItems,
                  userName: userName,
                  title: "Workspace",
                  itemLabel: "ITEMS",
                  onRefresh: () => _refreshAll(context, homeNotifier),
                ),
            SizedBox(height: 14.h),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: palette.line, width: 1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Row(
                  children: [
                    AppIcons.icon(
                      AppIcons.search,
                      size: 16.sp,
                      color: palette.muted,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: palette.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search notes, tasks, reminders...",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: palette.muted,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 18.sp,
                          color: palette.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Queued changes the server refused (retry / discard)
            const SyncFailuresBanner(),

            // Segmented Filter Chips Row: All, Notes, Tasks, Reminders
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _filters.map((filter) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _buildFilterChip(filter, palette),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Unified Workspace Feed
            Expanded(
              child: homeState.when(
                data: (_) {
                  return _buildFeedList(
                    context: context,
                    palette: palette,
                    notes: displayedNotes,
                    tasks: displayedTasks,
                    reminders: displayedReminders,
                    onRefresh: () => _refreshAll(context, homeNotifier),
                  );
                },
                loading: () => notesLoadingWidget(),
                error: (error, stack) => notesErrorWidget(
                  message: error.toString(),
                  onRetry: () => _refreshAll(context, homeNotifier),
                ),
              ),
            ),
          ],
        ),
      ),
      // Full-screen dismissable background scrim when Speed Dial is open
      if (_isSpeedDialOpen)
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isSpeedDialOpen = false;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
        ),
    ],
  ),
);
  }

  Widget _buildFilterChip(String label, DaymarkPalette palette) {
    final isSelected = _selectedFilter == label;
    final isDark = palette.brightness == Brightness.dark;

    final bg = isSelected
        ? (isDark ? palette.accent : palette.ink)
        : palette.surface;
    final fg = isSelected
        ? (isDark ? palette.background : palette.surface)
        : palette.muted;
    final border = isSelected ? Colors.transparent : palette.line;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: border, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedList({
    required BuildContext context,
    required DaymarkPalette palette,
    required List<NoteItem> notes,
    required List<TaskItem> tasks,
    required List<ReminderItem> reminders,
    required Future<void> Function() onRefresh,
  }) {
    final showNotes = _selectedFilter == "All" || _selectedFilter == "Notes";
    final showTasks = _selectedFilter == "All" || _selectedFilter == "Tasks";
    final showReminders = _selectedFilter == "All" || _selectedFilter == "Reminders";

    final hasAnyItems = (showNotes && notes.isNotEmpty) ||
        (showTasks && tasks.isNotEmpty) ||
        (showReminders && reminders.isNotEmpty);

    if (!hasAnyItems) {
      if (_searchQuery.isNotEmpty) {
        return Center(
          child: Text(
            "No results match your search.",
            style: GoogleFonts.inter(fontSize: 14.sp, color: palette.muted),
          ),
        );
      }
      return _buildEmptyWidget(palette, onRefresh);
    }

    return RefreshIndicator(
      color: palette.accent,
      backgroundColor: palette.surface,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(bottom: 90.h),
        children: [
          // Tasks Section
          if (showTasks && tasks.isNotEmpty) ...[
            if (_selectedFilter == "All") ...[
              _buildSectionHeader("Tasks (${tasks.length})", palette),
              SizedBox(height: 8.h),
            ],
            ...tasks.map((task) {
              return taskItemCard(
                context: context,
                task: task,
                onToggleComplete: (val) {
                  if (task.taskId != null) {
                    ref.read(taskController.notifier).toggleTaskStatus(
                          task.taskId!,
                          val,
                        );
                  }
                },
                onDelete: () {
                  if (task.taskId != null) {
                    ref.read(taskController.notifier).deleteTask(task.taskId!);
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
            if (_selectedFilter == "All") SizedBox(height: 12.h),
          ],

          // Reminders Section
          if (showReminders && reminders.isNotEmpty) ...[
            if (_selectedFilter == "All") ...[
              _buildSectionHeader("Reminders (${reminders.length})", palette),
              SizedBox(height: 8.h),
            ],
            ...reminders.map((reminder) {
              return reminderItemCard(
                context: context,
                reminder: reminder,
                onStatusChange: (newStatus) {
                  if (reminder.reminderId != null) {
                    ref.read(reminderController.notifier).updateReminderStatus(
                          reminder.reminderId!,
                          newStatus,
                        );
                  }
                },
                onDelete: () {
                  if (reminder.reminderId != null) {
                    ref.read(reminderController.notifier).deleteReminder(
                          reminder.reminderId!,
                        );
                  }
                },
                onStatusSelected: (status) {
                  if (reminder.reminderId != null) {
                    ref.read(reminderController.notifier).updateReminderStatus(
                          reminder.reminderId!,
                          status,
                        );
                  }
                },
              );
            }),
            if (_selectedFilter == "All") SizedBox(height: 12.h),
          ],

          // Notes Section
          if (showNotes && notes.isNotEmpty) ...[
            if (_selectedFilter == "All") ...[
              _buildSectionHeader("Notes (${notes.length})", palette),
              SizedBox(height: 8.h),
            ],
            ...notes.map((note) {
              return noteItemCard(
                context: context,
                note: note,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteDetailsScreen(noteId: note.noteId),
                    ),
                  );
                  if (result == true && context.mounted) {
                    onRefresh();
                  }
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(DaymarkPalette palette, Future<void> Function() onRefresh) {
    String title;
    String subtitle;

    switch (_selectedFilter) {
      case "Tasks":
        title = "No tasks yet";
        subtitle = "Keep track of your to-dos.\nTap '+ Add' and choose 'New Task' to get started.";
        break;
      case "Reminders":
        title = "No reminders yet";
        subtitle = "Never miss what matters.\nTap '+ Add' and choose 'New Reminder' to schedule one.";
        break;
      case "Notes":
        title = "No notes yet";
        subtitle = "Your calm space is waiting.\nTap '+ Add' and choose 'New Note' to capture your thoughts.";
        break;
      default:
        title = "Your workspace is clear";
        subtitle = "No notes, tasks, or reminders found.\nTap '+ Add' below to create something new.";
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          color: palette.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 72.r,
                        height: 72.r,
                        decoration: BoxDecoration(
                          color: palette.accentSoft,
                          borderRadius: BorderRadius.circular(22.r),
                          border: Border.all(color: palette.line),
                        ),
                        child: Center(
                          child: Icon(
                            _selectedFilter == "Tasks"
                                ? Icons.check_circle_outline_rounded
                                : (_selectedFilter == "Reminders"
                                    ? Icons.notifications_active_outlined
                                    : Icons.edit_note_rounded),
                            size: 32.sp,
                            color: palette.accent,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, DaymarkPalette palette) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: palette.muted,
      ),
    );
  }
}
