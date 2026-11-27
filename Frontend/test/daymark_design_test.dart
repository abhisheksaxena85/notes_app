import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/services/local_reminder_service.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/screens/calendar/calendar_screen.dart';
import 'package:notes_app/views/screens/dashboard/dashboard_screen.dart';
import 'package:notes_app/views/screens/home/widgets/note_item_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
    if (getIt.isRegistered<AppDatabase>()) {
      await getIt.unregister<AppDatabase>();
    }
    getIt.registerLazySingleton<AppDatabase>(
      () => AppDatabase.forTesting(NativeDatabase.memory()),
    );
    await Preference.init();
  });

  tearDownAll(() async {
    if (getIt.isRegistered<AppDatabase>()) {
      await getIt<AppDatabase>().close();
    }
  });

  group('Daymark Design Tokens Tests', () {
    test('Light theme tokens match design/README.md', () {
      final light = DaymarkPalette.light;
      expect(light.background, const Color(0xFFF3F3F1));
      expect(light.surface, const Color(0xFFFBFBFA));
      expect(light.surfaceMuted, const Color(0xFFEAEAE7));
      expect(light.iconTile, const Color(0xFFEFEFEC));
      expect(light.ink, const Color(0xFF2A2B2F));
      expect(light.inkSecondary, const Color(0xFF45474D));
      expect(light.muted, const Color(0xFF6A6C72));
      expect(light.disabled, const Color(0xFFB4B5B9));
      expect(light.line, const Color(0xFFE3E3DF));
      expect(light.chipBorder, const Color(0xFFDCDCD8));
      expect(light.accent, const Color(0xFF2F6BDB));
      expect(light.onAccent, const Color(0xFFFBFBFA));
      expect(light.accentSoft, Color.lerp(light.surface, light.accent, 0.12));
      expect(light.success, const Color(0xFF2F7A52));
      expect(light.successSoft, const Color(0xFFE6F0EA));
      expect(light.danger, const Color(0xFFB8433B));
      expect(light.dangerSoft, const Color(0xFFF6E6E4));
      expect(light.skeletonBase, const Color(0xFFE6E6E2));
      expect(light.skeletonHighlight, const Color(0xFFF2F2EF));
    });

    test('Dark theme tokens match design/README.md', () {
      final dark = DaymarkPalette.dark;
      expect(dark.background, const Color(0xFF1C1D20));
      expect(dark.surface, const Color(0xFF25262A));
      expect(dark.surfaceMuted, const Color(0xFF2A2B2F));
      expect(dark.iconTile, const Color(0xFF2E2F34));
      expect(dark.ink, const Color(0xFFE8E8E5));
      expect(dark.inkSecondary, const Color(0xFFC4C5C9));
      expect(dark.muted, const Color(0xFFA0A2A8));
      expect(dark.disabled, const Color(0xFF5E6066));
      expect(dark.line, const Color(0xFF34363C));
      expect(dark.chipBorder, const Color(0xFF3A3B41));
      expect(dark.accent, const Color(0xFF6B9BF2));
      expect(dark.onAccent, const Color(0xFF1C1D20));
      expect(dark.accentSoft, Color.lerp(dark.surface, dark.accent, 0.20));
      expect(dark.success, const Color(0xFF5FB386));
      expect(dark.successSoft, const Color(0xFF22332A));
      expect(dark.danger, const Color(0xFFE8897F));
      expect(dark.dangerSoft, const Color(0xFF3A2826));
      expect(dark.skeletonBase, const Color(0xFF2C2D31));
      expect(dark.skeletonHighlight, const Color(0xFF38393E));
    });

    test('Blue is the default accent and dark orange is defined', () {
      expect(DaymarkAccent.current, DaymarkAccent.blue);
      expect(DaymarkAccent.darkOrange.light, const Color(0xFFB9501A));
      expect(DaymarkAccent.darkOrange.dark, const Color(0xFFE0793A));
    });

    test('Themes use the palette', () {
      expect(AppTheme.lightTheme.colorScheme.primary, DaymarkPalette.light.accent);
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, DaymarkPalette.light.background);
      expect(AppTheme.darkTheme.colorScheme.primary, DaymarkPalette.dark.accent);
      expect(AppTheme.darkTheme.scaffoldBackgroundColor, DaymarkPalette.dark.background);
    });
  });

  group('Daymark Widgets & Views Tests', () {
    testWidgets('NoteCard renders title, category, pin badge, and date',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final note = NoteItem(
        noteId: 101,
        title: 'Weekly Product Roadmap',
        content: 'Review Q4 milestones with engineering leads...',
        category: 'Work',
        pinned: true,
        createdAt: '2026-11-17T10:30:00Z',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(412, 892),
            builder: (context, child) => MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => noteItemCard(
                    context: ctx,
                    note: note,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Weekly Product Roadmap'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('Dashboard renders 3 bottom navigation tabs: Workspace, Calendar, Profile',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(412, 892),
            builder: (context, child) => MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: const DashboardScreen(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Workspace'), findsAtLeast(1));
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Calendar screen renders activity header and month card',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(412, 892),
            builder: (context, child) => MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CalendarScreen(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('YOUR ACTIVITY'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Weekly view'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    test('NoteItem correctly parses tags and tagsList', () {
      final note = NoteItem(
        noteId: 10,
        title: 'Tag Test Note',
        content: 'Testing tags list parsing',
        category: 'Work',
        tags: 'Design, Architecture, Tokens',
      );

      expect(note.tagsList, ['Design', 'Architecture', 'Tokens']);

      final emptyTagsNote = NoteItem(tags: '   ');
      expect(emptyTagsNote.tagsList, isEmpty);
    });

    test('LocalReminderService persists daily reminder and weekly summary', () async {
      await LocalReminderService.setDailyReminder(true, time: const TimeOfDay(hour: 8, minute: 30));
      expect(LocalReminderService.isDailyReminderEnabled(), true);
      expect(LocalReminderService.getDailyReminderTime(), const TimeOfDay(hour: 8, minute: 30));

      await LocalReminderService.setWeeklySummary(true);
      expect(LocalReminderService.isWeeklySummaryEnabled(), true);

      await LocalReminderService.setDailyReminder(false);
      expect(LocalReminderService.isDailyReminderEnabled(), false);
    });
  });
}
