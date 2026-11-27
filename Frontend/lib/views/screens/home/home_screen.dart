import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/viewmodel/home/home_viewmodel.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_form_modal.dart';
import 'package:notes_app/views/screens/home/widgets/create_task_modal.dart';
import 'package:notes_app/views/screens/home/widgets/note_item_card.dart';
import 'package:notes_app/views/screens/home/widgets/notes_error_widget.dart';
import 'package:notes_app/views/screens/home/widgets/workspace_header.dart';
import 'package:notes_app/views/screens/home/widgets/workspace_loading_widget.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_item_card.dart';
import 'package:notes_app/views/screens/home/widgets/sync_failures_banner.dart';
import 'package:notes_app/views/screens/home/widgets/task_item_card.dart';
import 'package:notes_app/views/screens/note_details/note_details_screen.dart';
import 'package:notes_app/views/widgets/add_menu_fab.dart';
import 'package:notes_app/views/widgets/daymark_chip.dart';
import 'package:notes_app/views/widgets/icon_tile.dart';
import 'package:notes_app/views/widgets/section_header.dart';
import 'package:notes_app/views/widgets/notification_permission_prompt.dart';
import 'package:notes_app/views/widgets/undo_delete.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onOpenProfile});

  /// The header avatar opens the Profile tab.
  final VoidCallback? onOpenProfile;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = "All"; // "All", "Notes", "Tasks", "Reminders"
  String _searchQuery = "";
  bool _isSpeedDialOpen = false;

  final List<String> _filters = ["All", "Notes", "Tasks", "Reminders"];

  /// FE-06: items deleted with an "Undo" snackbar still open (or already
  /// deleted), hidden until the delete lands. Keyed by clientId, which stays
  /// the same when a local item gets its server id during the undo window.
  final Set<String> _hiddenTasks = {};
  final Set<String> _hiddenReminders = {};

  static String _taskKey(TaskItem t) => t.clientId ?? 'id:${t.taskId}';
  static String _reminderKey(ReminderItem r) =>
      r.clientId ?? 'id:${r.reminderId}';

  void _deleteTask(TaskItem task) {
    final id = task.taskId;
    if (id == null) return;
    final key = _taskKey(task);
    final tasks = ref.read(taskController.notifier);
    deleteWithUndo(
      messenger: ScaffoldMessenger.of(context),
      message: 'Task deleted',
      hide: () => setState(() => _hiddenTasks.add(key)),
      restore: () {
        if (mounted) setState(() => _hiddenTasks.remove(key));
      },
      delete: () => tasks.deleteTask(id),
    );
  }

  void _deleteReminder(ReminderItem reminder) {
    final id = reminder.reminderId;
    if (id == null) return;
    final key = _reminderKey(reminder);
    final reminders = ref.read(reminderController.notifier);
    deleteWithUndo(
      messenger: ScaffoldMessenger.of(context),
      message: 'Reminder deleted',
      hide: () => setState(() => _hiddenReminders.add(key)),
      restore: () {
        if (mounted) setState(() => _hiddenReminders.remove(key));
      },
      delete: () => reminders.deleteReminder(id),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll(BuildContext context, HomeViewmodel notifier) async {
    try {
      await Future.wait([
        notifier.getAllNotes(),
        ref.read(taskController.notifier).refreshTasks(),
        ref.read(reminderController.notifier).refreshReminders(),
      ]);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not refresh items. ${userMessage(error)}'),
        ),
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
    var list = rawTasks
        .where((t) => !_hiddenTasks.contains(_taskKey(t)))
        .toList();
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
    var list = rawReminders
        .where((r) => !_hiddenReminders.contains(_reminderKey(r)))
        .toList();
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

  /// A status from the card, or a REM-05 RepeatingChoice for repeats.
  void _applyReminderChoice(ReminderItem reminder, String choice) {
    final id = reminder.reminderId;
    if (id != null) {
      ref.read(reminderController.notifier).applyChoice(id, choice);
    }
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

    final visibleTasks = allTasks.where(
      (t) => !_hiddenTasks.contains(_taskKey(t)),
    );
    final visibleReminders = allReminders.where(
      (r) => !_hiddenReminders.contains(_reminderKey(r)),
    );
    final today = DateTime.now();
    final tasksToday = visibleTasks.where((t) {
      final due = DisplayFormat.day(t.dueDate);
      return due != null && DisplayFormat.sameDay(due, today);
    }).length;

    Future<void> onRefresh() => _refreshAll(context, homeNotifier);
    // First load: the whole screen is a skeleton (data on later refreshes
    // stays on screen).
    final isLoading = homeState.isLoading && !homeState.hasValue;

    return Scaffold(
      backgroundColor: palette.background,
      // 20 from the right edge and 18 above the nav (Scaffold adds 16).
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 2, right: 4),
        child: AddMenuFab(
          enabled: !isLoading,
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
            final res = await showReminderFormModal(context);
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
            bottom: false,
            child: isLoading
                ? const WorkspaceLoadingWidget()
                : RefreshIndicator(
                    color: palette.accent,
                    backgroundColor: palette.surface,
                    onRefresh: onRefresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          sliver: SliverList.list(
                            children: [
                              WorkspaceHeader(
                                userName: userName,
                                onAvatarTap: widget.onOpenProfile,
                              ),
                              const SizedBox(height: 18),
                              WorkspaceStats(
                                tasksToday: tasksToday,
                                reminders: visibleReminders.length,
                                notes: allNotes.length,
                              ),
                              const SizedBox(height: 14),
                              WorkspaceSearchField(
                                controller: _searchController,
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                                onClear: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = "");
                                },
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),

                        // Queued changes the server refused (retry / discard)
                        const SliverToBoxAdapter(child: SyncFailuresBanner()),

                        // REM-02: upcoming reminders that won't alert
                        SliverToBoxAdapter(
                          child: NotificationsOffBanner(
                            permissions: getIt<NotificationPermissionService>(),
                            hasUpcomingReminders: allReminders.any(
                              (r) => r.isUpcoming(),
                            ),
                          ),
                        ),

                        // Filter chips: All, Notes, Tasks, Reminders
                        SliverToBoxAdapter(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                for (final filter in _filters) ...[
                                  DaymarkChip(
                                    label: filter,
                                    selected: _selectedFilter == filter,
                                    onTap: () => setState(
                                      () => _selectedFilter = filter,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 22)),

                        // Unified Workspace Feed
                        ...homeState.when(
                          data: (_) => _buildFeed(
                            context: context,
                            palette: palette,
                            notes: displayedNotes,
                            tasks: displayedTasks,
                            reminders: displayedReminders,
                            onRefresh: onRefresh,
                          ),
                          loading: () => const [],
                          error: (error, stack) => [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: notesErrorWidget(
                                message: userMessage(error),
                                onRetry: onRefresh,
                              ),
                            ),
                          ],
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
          ),
          // Full-screen dismissable scrim while the add menu is open
          if (_isSpeedDialOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isSpeedDialOpen = false;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(color: palette.scrim),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFeed({
    required BuildContext context,
    required DaymarkPalette palette,
    required List<NoteItem> notes,
    required List<TaskItem> tasks,
    required List<ReminderItem> reminders,
    required Future<void> Function() onRefresh,
  }) {
    final isAll = _selectedFilter == "All";
    final showNotes = isAll || _selectedFilter == "Notes";
    final showTasks = isAll || _selectedFilter == "Tasks";
    final showReminders = isAll || _selectedFilter == "Reminders";

    final hasAnyItems =
        (showNotes && notes.isNotEmpty) ||
        (showTasks && tasks.isNotEmpty) ||
        (showReminders && reminders.isNotEmpty);

    if (!hasAnyItems) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _searchQuery.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    "No results match your search.",
                    textAlign: TextAlign.center,
                    style: DaymarkText.custom(
                      14,
                      FontWeight.w400,
                    ).copyWith(color: palette.muted),
                  ),
                )
              : _buildEmptyWidget(palette),
        ),
      ];
    }

    Widget header(String title, int count, String filter) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionHeader(
        title: title,
        count: count,
        onSeeAll: isAll ? () => setState(() => _selectedFilter = filter) : null,
      ),
    );

    final children = <Widget>[
      // Tasks Section
      if (showTasks && tasks.isNotEmpty) ...[
        header("Tasks", tasks.length, "Tasks"),
        ...tasks.map((task) {
          return taskItemCard(
            context: context,
            task: task,
            onToggleComplete: (val) {
              if (task.taskId != null) {
                ref
                    .read(taskController.notifier)
                    .toggleTaskStatus(task.taskId!, val);
              }
            },
            // FE-06: tap to edit.
            onTap: task.taskId == null
                ? null
                : () => showCreateTaskModal(context, initial: task),
            onDelete: () => _deleteTask(task),
            onStatusSelected: (status) {
              if (task.taskId != null) {
                ref
                    .read(taskController.notifier)
                    .setTaskStatus(task.taskId!, status);
              }
            },
          );
        }),
        const SizedBox(height: 14),
      ],

      // Reminders Section
      if (showReminders && reminders.isNotEmpty) ...[
        header("Reminders", reminders.length, "Reminders"),
        ...reminders.map((reminder) {
          return ValueListenableBuilder<NotificationStatus>(
            valueListenable: getIt<NotificationPermissionService>().status,
            builder: (context, alerts, _) => reminderItemCard(
              context: context,
              reminder: reminder,
              alerts: alerts,
              // REM-06: tap to edit.
              onTap: reminder.reminderId == null
                  ? null
                  : () => showReminderFormModal(context, initial: reminder),
              onStatusChange: (newStatus) =>
                  _applyReminderChoice(reminder, newStatus),
              onDelete: () => _deleteReminder(reminder),
              onStatusSelected: (status) =>
                  _applyReminderChoice(reminder, status),
            ),
          );
        }),
        const SizedBox(height: 14),
      ],

      // Notes Section
      if (showNotes && notes.isNotEmpty) ...[
        header("Notes", notes.length, "Notes"),
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
    ];

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.list(children: children),
      ),
    ];
  }

  Widget _buildEmptyWidget(DaymarkPalette palette) {
    String title;
    String subtitle;
    String icon;

    switch (_selectedFilter) {
      case "Tasks":
        title = "No tasks yet";
        subtitle = "Keep track of your to-dos.\nTap + and choose New task to get started.";
        icon = AppIcons.task;
        break;
      case "Reminders":
        title = "No reminders yet";
        subtitle = "Never miss what matters.\nTap + and choose New reminder to schedule one.";
        icon = AppIcons.reminder;
        break;
      case "Notes":
        title = "No notes yet";
        subtitle = "Your calm space is waiting.\nTap + and choose New note to capture your thoughts.";
        icon = AppIcons.note;
        break;
      default:
        title = "Your workspace is clear";
        subtitle = "No notes, tasks, or reminders yet.\nTap + to create something new.";
        icon = AppIcons.workspace;
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconTile(
            icon: icon,
            size: 56,
            radius: 18,
            iconSize: 26,
            background: palette.accentSoft,
            color: palette.accent,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DaymarkText.custom(
              17,
              FontWeight.w600,
            ).copyWith(color: palette.ink),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: DaymarkText.preview.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}
