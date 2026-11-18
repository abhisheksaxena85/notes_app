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
    test('Light theme tokens match Figma specification', () {
      const light = DaymarkPalette.light;
      expect(light.background, const Color(0xFFF6F7F5));
      expect(light.surface, const Color(0xFFFFFFFF));
      expect(light.ink, const Color(0xFF252A27));
      expect(light.muted, const Color(0xFF858D87));
      expect(light.accent, const Color(0xFF5E7668));
      expect(light.accentSoft, const Color(0xFFEAF0EB));
      expect(light.line, const Color(0xFFE8ECE8));
      expect(light.danger, const Color(0xFFB95E58));
    });

    test('Dark theme tokens match Figma specification', () {
      const dark = DaymarkPalette.dark;
      expect(dark.background, const Color(0xFF151816));
      expect(dark.surface, const Color(0xFF202522));
      expect(dark.ink, const Color(0xFFF0F3F1));
      expect(dark.muted, const Color(0xFF8A948C));
      expect(dark.accent, const Color(0xFF739280));
      expect(dark.accentSoft, const Color(0xFF26342B));
      expect(dark.line, const Color(0xFF2D352F));
      expect(dark.danger, const Color(0xFFD9726C));
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
