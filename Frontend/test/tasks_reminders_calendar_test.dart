import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/screens/calendar/calendar_screen.dart';
import 'package:notes_app/views/widgets/add_menu_fab.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_item_card.dart';
import 'package:notes_app/views/screens/home/widgets/task_item_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
    if (getIt.isRegistered<AppDatabase>()) {
      await getIt.unregister<AppDatabase>();
    }
    db = AppDatabase.forTesting(NativeDatabase.memory());
    getIt.registerLazySingleton<AppDatabase>(() => db);
    await Preference.init();
  });

  tearDownAll(() async {
    await db.close();
  });

  group('Task & Reminder Entity Mapping & Offline Queuing Tests', () {
    test('TaskItem fromJson and toJson round-trip', () {
      final task = TaskItem(
        taskId: 1,
        title: 'Ship Calendar Badges',
        description: 'Implement numerical count badges',
        dueDate: '2026-11-19',
        dueTime: '15:00',
        category: 'Work',
        priority: 'HIGH',
        status: 'PENDING',
        isCompleted: false,
      );

      final json = task.toJson();
      final revived = TaskItem.fromJson(json);

      expect(revived.title, 'Ship Calendar Badges');
      expect(revived.dueDate, '2026-11-19');
      expect(revived.dueTime, '15:00');
      expect(revived.priority, 'HIGH');
      expect(revived.status, 'PENDING');
      expect(revived.isCompleted, isFalse);
    });

    test('ReminderItem fromJson and toJson round-trip', () {
      final reminder = ReminderItem(
        reminderId: 10,
        title: 'Team Standup',
        remindAt: '2026-11-19T09:30:00',
        dueDate: '2026-11-19',
        dueTime: '09:30',
        category: 'Work',
        status: 'PENDING',
        repeatInterval: 'DAILY',
      );

      final json = reminder.toJson();
      final revived = ReminderItem.fromJson(json);

      expect(revived.title, 'Team Standup');
      expect(revived.remindAt, '2026-11-19T09:30:00');
      expect(revived.dueDate, '2026-11-19');
      expect(revived.dueTime, '09:30');
      expect(revived.repeatInterval, 'DAILY');
      expect(revived.status, 'PENDING');
    });

    test('TaskRepo enqueues offline task in database', () async {
      final taskRepo = getIt<TaskRepo>();
      final localId = await taskRepo.enqueueTask(
        CreateTaskRequestDto(
          userId: 42,
          title: 'Offline Task Test',
          description: 'Testing SQLite queuing',
          dueDate: '2026-11-20',
          dueTime: '10:00',
          category: 'Personal',
          priority: 'MEDIUM',
        ),
      );

      expect(localId, greaterThan(0));

      final cached = await taskRepo.getCachedTasks(42);
      expect(cached.any((t) => t.title == 'Offline Task Test'), isTrue);

      final pending = await db.getPendingTasks(42);
      expect(pending.any((p) => p.localTaskId == localId), isTrue);
    });

    test('ReminderRepo enqueues offline reminder in database', () async {
      final reminderRepo = getIt<ReminderRepo>();
      final localId = await reminderRepo.enqueueReminder(
        CreateReminderRequestDto(
          userId: 42,
          title: 'Offline Reminder Test',
          remindAt: '2026-11-20T08:00:00',
          dueDate: '2026-11-20',
          dueTime: '08:00',
          category: 'Personal',
        ),
      );

      expect(localId, greaterThan(0));

      final cached = await reminderRepo.getCachedReminders(42);
      expect(cached.any((r) => r.title == 'Offline Reminder Test'), isTrue);

      final pending = await db.getPendingReminders(42);
      expect(pending.any((p) => p.localReminderId == localId), isTrue);
    });
  });

  group('Task & Reminder UI Cards status rules', () {
    final palette = DaymarkPalette.light;

    Widget host(Widget Function(BuildContext) child) => ScreenUtilInit(
          designSize: const Size(412, 892),
          builder: (context, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: Builder(builder: child)),
          ),
        );

    /// Decorations of the animated status controls (checkbox / bell tile).
    Iterable<BoxDecoration> statusDecorations(WidgetTester tester) => tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>();

    bool hasRing(WidgetTester tester, Color color) => statusDecorations(tester)
        .any((d) => d.border is Border && (d.border as Border).top.color == color);

    testWidgets('a pending task has an accent ring and no strikethrough',
        (WidgetTester tester) async {
      final task = TaskItem(
        taskId: 1,
        title: 'Pending Feature',
        dueDate: '2099-11-20',
        status: 'PENDING',
        isCompleted: false,
      );
      await tester.pumpWidget(host((ctx) => taskItemCard(
            context: ctx,
            task: task,
            onToggleComplete: (_) {},
          )));
      await tester.pump();

      final textWidget = tester.widget<Text>(find.text('Pending Feature'));
      expect(textWidget.style?.decoration, isNull);
      expect(hasRing(tester, palette.accent), isTrue);
      expect(find.text('Missed'), findsNothing);
    });

    testWidgets('a completed task has a success fill, strikethrough and Done',
        (WidgetTester tester) async {
      final task = TaskItem(
        taskId: 2,
        title: 'Completed Feature',
        dueDate: '2026-11-19',
        status: 'COMPLETED',
        isCompleted: true,
      );
      await tester.pumpWidget(host((ctx) => taskItemCard(
            context: ctx,
            task: task,
            onToggleComplete: (_) {},
          )));
      await tester.pump();

      final textWidget = tester.widget<Text>(find.text('Completed Feature'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
      expect(textWidget.style?.color, palette.muted);
      expect(statusDecorations(tester).any((d) => d.color == palette.success), isTrue);
      final done = tester.widget<Text>(find.text('Done'));
      expect(done.style?.color, palette.success);
    });

    testWidgets('a missed task has a danger ring and a Missed pill',
        (WidgetTester tester) async {
      final task = TaskItem(
        taskId: 3,
        title: 'Missed Feature',
        dueDate: '2026-11-18',
        status: 'MISSED',
        isCompleted: false,
      );
      await tester.pumpWidget(host((ctx) => taskItemCard(
            context: ctx,
            task: task,
            onToggleComplete: (_) {},
          )));
      await tester.pump();

      expect(hasRing(tester, palette.danger), isTrue);
      final pill = tester.widget<Text>(find.text('Missed'));
      expect(pill.style?.color, palette.danger);
    });

    testWidgets('reminder tiles follow pending / missed / completed',
        (WidgetTester tester) async {
      Future<void> pumpReminder(ReminderItem reminder) async {
        await tester.pumpWidget(host((ctx) => reminderItemCard(
              context: ctx,
              reminder: reminder,
              onStatusChange: (_) {},
            )));
        await tester.pump();
      }

      bool tile(Color fill) =>
          statusDecorations(tester).any((d) => d.color == fill);

      // Far future: an overdue PENDING reminder is rendered as MISSED.
      await pumpReminder(ReminderItem(
        reminderId: 4,
        title: 'Doctor Appointment',
        remindAt: '2099-11-19T14:00:00',
        dueDate: '2099-11-19',
        status: 'PENDING',
      ));
      expect(tile(palette.accentSoft), isTrue);

      await pumpReminder(ReminderItem(
        reminderId: 5,
        title: 'Overdue',
        remindAt: '2020-01-01T09:00:00',
        dueDate: '2020-01-01',
        status: 'PENDING',
      ));
      expect(tile(palette.dangerSoft), isTrue);
      expect(find.text('Missed'), findsOneWidget);

      await pumpReminder(ReminderItem(
        reminderId: 6,
        title: 'Finished',
        remindAt: '2099-11-19T14:00:00',
        dueDate: '2099-11-19',
        status: 'COMPLETED',
      ));
      expect(tile(palette.successSoft), isTrue);
    });
  });

  group('Add menu FAB Tests', () {
    testWidgets('AddMenuFab opens on tap and reveals the add menu',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool noteClicked = false;
      bool taskClicked = false;
      bool reminderClicked = false;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(412, 892),
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              floatingActionButton: AddMenuFab(
                onNewNote: () => noteClicked = true,
                onNewTask: () => taskClicked = true,
                onNewReminder: () => reminderClicked = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Initially closed: the FAB is labelled 'Add' and the menu is hidden
      expect(find.bySemanticsLabel('Add'), findsOneWidget);
      expect(find.text('New note'), findsNothing);

      // Tap main FAB
      await tester.tap(find.bySemanticsLabel('Add'));
      await tester.pumpAndSettle();

      // Now open: the FAB is a close button and the menu rows are visible
      expect(find.bySemanticsLabel('Close'), findsOneWidget);
      expect(find.text('New note'), findsOneWidget);
      expect(find.text('New task'), findsOneWidget);
      expect(find.text('New reminder'), findsOneWidget);

      // Tap New task
      await tester.tap(find.text('New task'));
      await tester.pumpAndSettle();

      expect(taskClicked, isTrue);
      expect(noteClicked, isFalse);
      expect(reminderClicked, isFalse);
    });
  });

  group('Calendar Screen Numerical Count Badge Tests', () {
    testWidgets('Calendar screen renders numerical badge instead of single dot',
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
      expect(
        find.text('Badges show item count (Notes, Tasks, Reminders)'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
