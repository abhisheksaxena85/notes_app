import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_form_modal.dart';

import 'support/fake_server.dart';

/// REM-06: the reminder form (create and edit), no past times, and edits
/// that work offline and before the first sync.
void main() {
  group('validateReminderTime', () {
    final now = DateTime(2026, 11, 26, 18, 0, 30);
    final today = DateTime(2026, 11, 26);

    test('a time that has passed today is refused', () {
      expect(validateReminderTime(date: today, time: const TimeOfDay(hour: 17, minute: 0), now: now),
          isNotNull);
    });

    test('less than a minute ahead is refused, a minute or more is fine', () {
      expect(validateReminderTime(date: today, time: const TimeOfDay(hour: 18, minute: 1), now: now),
          isNotNull, reason: '18:01:00 is only 30 s away');
      expect(validateReminderTime(date: today, time: const TimeOfDay(hour: 18, minute: 2), now: now),
          isNull);
    });

    test('any time on a later day is fine', () {
      expect(validateReminderTime(
              date: DateTime(2026, 11, 27), time: const TimeOfDay(hour: 0, minute: 0), now: now),
          isNull);
    });
  });

  Widget host(Widget child) => ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(412, 892),
      builder: (_, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );

  testWidgets('create: a past time shows the inline error and does not save', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 11, 26, 18, 0);
    await tester.pumpWidget(host(ReminderFormModal(
      now: () => now,
      initialDateTime: DateTime(2026, 11, 26, 17, 30),
    )));
    await tester.enterText(find.byType(TextField), 'Call the bank');
    await tester.tap(find.text('Create reminder'));
    await tester.pump();

    expect(find.text('Pick a time at least 1 minute from now.'), findsOneWidget);
    expect(find.text('New reminder'), findsOneWidget, reason: 'still open');
  });

  testWidgets('edit: the form is prefilled and offers delete', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(ReminderFormModal(
      now: () => DateTime(2026, 11, 26, 9),
      initial: ReminderItem(
        reminderId: 7,
        title: 'Water plants',
        remindAt: '2026-11-28T07:45:00',
        category: 'Home',
        repeatInterval: 'WEEKLY',
      ),
    )));

    expect(find.text('Edit reminder'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Water plants'), findsOneWidget);
    expect(find.text('Sat, 28 Nov 2026'), findsOneWidget);
    expect(find.text('7:45 AM'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Weekly')).style?.fontWeight, FontWeight.w600, reason: 'selected segment');
    expect(tester.widget<Text>(find.text('Daily')).style?.fontWeight, FontWeight.w500);
    expect(tester.widget<Text>(find.text('Home')).style?.color, DaymarkPalette.light.accent, reason: 'selected category');
  });

  group('edits are local first', () {
    const userId = 42;
    late AppDatabase database;
    late FakeServer server;
    late OfflineSyncService sync;
    late ReminderRepo repo;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      server = FakeServer();
      sync = OfflineSyncService(client: server, database: database);
      repo = ReminderRepo(client: server, database: database, syncService: sync);
    });

    tearDown(() async {
      await sync.dispose();
      await database.close();
    });

    Future<int> create() => repo.enqueueReminder(CreateReminderRequestDto(
      userId: userId,
      title: 'Dentist',
      remindAt: '2026-12-01T09:00:00',
      dueDate: '2026-12-01',
      dueTime: '09:00',
    ));

    test('an unsynced reminder edited offline syncs as one create with the final values', () async {
      final id = await create();
      await repo.snoozeReminder(userId, id, DateTime.utc(2026, 12, 1, 14));
      await repo.updateReminder(userId,
          UpdateReminderRequestDto(reminderId: -id, title: 'Dentist (moved)', remindAt: '2026-12-02T16:30'));

      final row = (await database.getReminderRow(userId, id))!;
      expect(row.title, 'Dentist (moved)');
      expect(row.remindAt, '2026-12-02T16:30:00');
      expect((row.dueDate, row.dueTime), ('2026-12-02', '16:30'));
      expect(row.startAt, '2026-12-02T16:30:00');
      expect(row.snoozedUntil, isNull, reason: 'a new time drops the snooze');

      sync.setUserId(userId);
      await sync.requestSync();
      expect(server.count('createReminder'), 1);
      expect(server.count('updateReminder'), 0);
      final created = server.reminders.values.single;
      expect(created['title'], 'Dentist (moved)');
      expect(created['remindAt'], '2026-12-02T16:30:00');
      expect(created['dueDate'], '2026-12-02');
    });

    test('a synced reminder edited offline is updated on the server after reconnecting', () async {
      final id = await create();
      sync.setUserId(userId);
      await sync.requestSync();
      final serverId = (await database.getReminderRow(userId, id))!.serverId!;

      server.onRequest = (_, _) => throw FakeServer.offline();
      await repo.updateReminder(
          userId, UpdateReminderRequestDto(reminderId: serverId, remindAt: '2026-12-03T08:15:00'));
      final queued = (await database.getPendingMutations(userId)).single;
      expect(jsonDecode(queued.payload), containsPair('remindAt', '2026-12-03T08:15:00'));
      expect(jsonDecode(queued.payload), containsPair('startAt', '2026-12-03T08:15:00'));

      server.onRequest = null;
      await sync.requestSync();
      expect(server.reminders[serverId]!['remindAt'], '2026-12-03T08:15:00');
      expect(server.reminders[serverId]!['dueTime'], '08:15');
    });

    test('an invalid remindAt is refused before anything is written', () async {
      final id = await create();
      expect(
        () => repo.updateReminder(userId, UpdateReminderRequestDto(reminderId: -id, remindAt: 'soon')),
        throwsArgumentError,
      );
      expect((await database.getReminderRow(userId, id))!.remindAt, '2026-12-01T09:00:00');
    });
  });
}
