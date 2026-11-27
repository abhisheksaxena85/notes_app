import 'package:flutter/material.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/services/digest_scheduler.dart';
import 'package:notes_app/utils/services/home_widgets/widget_links.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';
import 'package:notes_app/views/screens/calendar/calendar_screen.dart';
import 'package:notes_app/views/screens/home/home_screen.dart';
import 'package:notes_app/views/screens/home/widgets/create_task_modal.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_form_modal.dart';
import 'package:notes_app/views/screens/profile/profile_screen.dart';
import 'package:notes_app/views/widgets/daymark_bottom_nav.dart';
import 'package:notes_app/views/widgets/quick_add_task_sheet.dart';
import 'package:notes_app/views/widgets/reminder_answer_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _prompting = false;

  @override
  void initState() {
    super.initState();
    reminderPromptRequests.addListener(_showReminderPrompt);
    widgetLinkRequests.addListener(_openWidgetLink);
    // A notification or widget tap that launched the app arrived before
    // this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showReminderPrompt();
      _openWidgetLink();
    });
  }

  @override
  void dispose() {
    reminderPromptRequests.removeListener(_showReminderPrompt);
    widgetLinkRequests.removeListener(_openWidgetLink);
    super.dispose();
  }

  /// W-01: a home-screen widget tap opens the Workspace, and the task,
  /// reminder or sheet it points at.
  Future<void> _openWidgetLink() async {
    final link = widgetLinkRequests.value;
    if (link == null || !mounted) return;
    widgetLinkRequests.value = null;
    setState(() => _currentIndex = 0);
    final userId = getIt<SessionService>().userId;
    if (userId == 0) return;
    switch (link) {
      case WorkspaceLink():
        return;
      case QuickAddTaskLink():
        await showQuickAddTaskSheet(context);
      case NewReminderLink():
        await showReminderFormModal(context);
      case OpenTaskLink(:final id):
        final tasks = await getIt<TaskRepo>().getCachedTasks(userId);
        final task = tasks.where((t) => t.taskId == id).firstOrNull;
        if (!mounted) return;
        if (task == null) return _showGone('task');
        await showCreateTaskModal(context, initial: task);
      case OpenReminderLink(:final id):
        final reminders = await getIt<ReminderRepo>().getCachedReminders(userId);
        final reminder = reminders.where((r) => r.reminderId == id).firstOrNull;
        if (!mounted) return;
        if (reminder == null) return _showGone('reminder');
        await showReminderFormModal(context, initial: reminder);
    }
  }

  void _showGone(String kind) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('That $kind no longer exists.')),
    );
  }

  /// REM-04: a tapped reminder notification opens the Workspace and asks
  /// "Did you complete it?".
  Future<void> _showReminderPrompt() async {
    final payload = reminderPromptRequests.value;
    if (payload == null || _prompting || !mounted) return;
    reminderPromptRequests.value = null;
    // REM-08: a digest opens the Workspace (daily) or the Calendar (weekly).
    final digest = digestKindOf(payload);
    if (digest != null) {
      setState(() => _currentIndex = digest == 'weekly' ? 1 : 0);
      return;
    }
    _prompting = true;
    try {
      setState(() => _currentIndex = 0);
      await promptForReminder(context, getIt<ReminderActionHandler>(), payload);
    } finally {
      _prompting = false;
    }
  }

  late final List<Widget> _pages = [
    HomeScreen(onOpenProfile: () => setState(() => _currentIndex = 2)),
    const CalendarScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;

    return Scaffold(
      backgroundColor: palette.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: DaymarkBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          DaymarkNavItem(icon: AppIcons.workspace, label: 'Workspace'),
          DaymarkNavItem(icon: AppIcons.calendar, label: 'Calendar'),
          DaymarkNavItem(icon: AppIcons.profile, label: 'Profile'),
        ],
      ),
    );
  }
}
