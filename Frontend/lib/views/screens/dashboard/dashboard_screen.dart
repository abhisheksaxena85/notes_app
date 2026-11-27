import 'package:flutter/material.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/services/digest_scheduler.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';
import 'package:notes_app/views/screens/calendar/calendar_screen.dart';
import 'package:notes_app/views/screens/home/home_screen.dart';
import 'package:notes_app/views/screens/profile/profile_screen.dart';
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
    // A notification tap that launched the app arrived before this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showReminderPrompt());
  }

  @override
  void dispose() {
    reminderPromptRequests.removeListener(_showReminderPrompt);
    super.dispose();
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

  final List<Widget> _pages = const [
    HomeScreen(),
    CalendarScreen(),
    ProfileScreen(),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border(
              top: BorderSide(color: palette.line, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                index: 0,
                iconPath: AppIcons.workspace,
                label: "Workspace",
                palette: palette,
              ),
              _buildNavItem(
                index: 1,
                iconPath: AppIcons.calendar,
                label: "Calendar",
                palette: palette,
              ),
              _buildNavItem(
                index: 2,
                iconPath: AppIcons.profile,
                label: "Profile",
                palette: palette,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required String label,
    required DaymarkPalette palette,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.w : 12.w,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? palette.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcons.icon(
              iconPath,
              size: 18,
              color: isSelected ? palette.ink : palette.muted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? palette.ink : palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
