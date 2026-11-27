import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';
import 'package:notes_app/utils/services/reminder_scheduler.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/widgets/reminder_answer_sheet.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_notification_platform.dart';
import 'support/fake_server.dart';

/// REM-04: Done / Not done / Snooze from a notification, applied once, saved
/// locally first and synced. In-memory database, fake OS and fake server.
void main() {
  const userId = 42;
  late tz.Location newYork;
  late AppDatabase database;
  late FakeServer server;
  late OfflineSyncService sync;
  late ReminderRepo repo;
  late FakeNotificationPlatform platform;
  late ReminderScheduler scheduler;
  late ReminderActionHandler handler;
  late tz.TZDateTime now;
  var signedIn = userId;

  setUpAll(() {
    tzdata.initializeTimeZones();
    newYork = tz.getLocation('America/New_York');
  });

  setUp(() {
    tz.setLocalLocation(newYork);
    now = tz.TZDateTime(newYork, 2026, 11, 26, 18, 1);
    signedIn = userId;
    database = AppDatabase.forTesting(NativeDatabase.memory());
    server = FakeServer();
    sync = OfflineSyncService(client: server, database: database);
    repo = ReminderRepo(client: server, database: database, syncService: sync);
    platform = FakeNotificationPlatform();
    scheduler = ReminderScheduler(
      database: database,
      repo: repo,
      notifications: NotificationService(platform: platform, supported: true, android: true),
      currentUserId: () => signedIn,
      now: () => now,
      use24h: () => false,
    );
    handler = ReminderActionHandler(
      database: database,
      repo: repo,
      scheduler: scheduler,
      currentUserId: () => signedIn,
      pushChanges: () {
        sync.setUserId(userId);
        return sync.requestSync();
      },
      now: () => now,
    );
  });

  tearDown(() async {
    await scheduler.dispose();
    await sync.dispose();
    await database.close();
  });

  /// A reminder that is already on the server (synced).
  Future<CachedReminder> synced(String remindAt, {String interval = 'NONE'}) async {
    final id = await repo.enqueueReminder(CreateReminderRequestDto(
      userId: userId,
      title: 'Take pills',
      remindAt: remindAt,
      repeatInterval: interval,
    ));
    sync.setUserId(userId);
    await sync.requestSync();
    final row = (await database.getReminderRow(userId, id))!;
    expect(row.serverId, isNotNull);
    return row;
  }

  String payloadFor(CachedReminder row, {String? occurrence, int? user, int? localId}) =>
      ReminderPayload(
        userId: user ?? userId,
        localId: localId ?? row.id,
        serverId: row.serverId,
        occurrence: occurrence ?? row.remindAt,
        fireAt: 'x',
      ).encode();

  Future<CachedReminder> reload(CachedReminder row) async =>
      (await database.getReminderRow(userId, row.id))!;

  group('one-off reminder', () {
    test('Done marks it completed locally and on the server', () async {
      final row = await synced('2026-11-26T18:00:00');
      final result = await handler.handle(ReminderActions.done, payloadFor(row));

      expect(result.outcome, ReminderActionOutcome.answered);
      expect((await reload(row)).status, 'COMPLETED');
      expect(server.reminders[row.serverId]!['status'], 'COMPLETED');
      expect(await database.getPendingMutations(userId), isEmpty, reason: 'synced');
    });

    test('Not done marks it missed', () async {
      final row = await synced('2026-11-26T18:00:00');
      await handler.handle(ReminderActions.notDone, payloadFor(row));
      expect((await reload(row)).status, 'MISSED');
      expect(server.reminders[row.serverId]!['status'], 'MISSED');
    });

    test('a second Done (duplicate callback, second device) applies once', () async {
      final row = await synced('2026-11-26T18:00:00');
      await handler.handle(ReminderActions.done, payloadFor(row));
      final second = await handler.handle(ReminderActions.done, payloadFor(row));
      final notDone = await handler.handle(ReminderActions.notDone, payloadFor(row));

      expect(second.outcome, ReminderActionOutcome.ignored);
      expect(notDone.outcome, ReminderActionOutcome.ignored);
      expect(server.count('updateReminderStatus'), 1);
      expect((await reload(row)).status, 'COMPLETED');
    });

    test('offline: saved locally, queued, and sent after reconnecting', () async {
      final row = await synced('2026-11-26T18:00:00');
      server.onRequest = (_, _) => throw FakeServer.offline();

      final result = await handler.handle(ReminderActions.done, payloadFor(row));
      expect(result.outcome, ReminderActionOutcome.answered);
      expect((await reload(row)).status, 'COMPLETED');
      expect((await database.getPendingMutations(userId)).single.op, 'status');

      server.onRequest = null;
      await sync.requestSync();
      expect(server.reminders[row.serverId]!['status'], 'COMPLETED');
    });

    test('a reminder never synced: the queued create carries the answer', () async {
      final id = await repo.enqueueReminder(CreateReminderRequestDto(
        userId: userId,
        title: 'Offline',
        remindAt: '2026-11-26T18:00:00',
      ));
      final row = (await database.getReminderRow(userId, id))!;
      server.onRequest = (_, _) => throw FakeServer.offline();
      await handler.handle(ReminderActions.done, payloadFor(row));

      server.onRequest = null;
      await sync.requestSync();
      expect(server.reminders.values.single['status'], 'COMPLETED');
      expect(server.count('createReminder'), 2, reason: 'one failed offline, one retry');
    });
  });

  test('Snooze brings it back in 10 minutes without changing it', () async {
    final row = await synced('2026-11-26T18:00:00');
    final result = await handler.handle(ReminderActions.snooze, payloadFor(row));

    expect(result.outcome, ReminderActionOutcome.snoozed);
    final after = await reload(row);
    expect(after.status, 'PENDING');
    expect(DateTime.parse(after.snoozedUntil!).isAtSameMomentAs(now.add(const Duration(minutes: 10))),
        isTrue);
    expect(platform.scheduled[row.id]!.at, tz.TZDateTime(newYork, 2026, 11, 26, 18, 11));
    expect(await database.getPendingMutations(userId), isEmpty, reason: 'nothing for the server');

    // Done on the snoozed notification clears the snooze.
    await handler.handle(ReminderActions.done, payloadFor(row));
    final done = await reload(row);
    expect(done.status, 'COMPLETED');
    expect(done.snoozedUntil, isNull);
    expect(platform.scheduled, isEmpty);
  });

  test('a deleted reminder, another user or a signed-out session are ignored', () async {
    final row = await synced('2026-11-26T18:00:00');

    expect((await handler.handle(ReminderActions.done, payloadFor(row, user: 7))).outcome,
        ReminderActionOutcome.ignored);
    signedIn = 0;
    expect((await handler.handle(ReminderActions.done, payloadFor(row))).outcome,
        ReminderActionOutcome.ignored);
    signedIn = userId;

    await repo.deleteReminder(userId, row.serverId!);
    expect((await handler.handle(ReminderActions.done, payloadFor(row))).outcome,
        ReminderActionOutcome.ignored);
    expect(server.count('updateReminderStatus'), 0);
  });

  test('a reminder edited since the notification was shown is not changed', () async {
    final row = await synced('2026-11-26T18:00:00');
    await repo.updateReminder(
        userId, UpdateReminderRequestDto(reminderId: row.serverId!, remindAt: '2026-11-27T09:00'));
    final result = await handler.handle(ReminderActions.done, payloadFor(row));
    expect(result.outcome, ReminderActionOutcome.ignored);
    expect((await reload(row)).status, 'PENDING');
  });

  test('found by server id when the local row was re-cached', () async {
    final row = await synced('2026-11-26T18:00:00');
    final result = await handler.handle(ReminderActions.done, payloadFor(row, localId: 999));
    expect(result.outcome, ReminderActionOutcome.answered);
    expect((await reload(row)).status, 'COMPLETED');
  });

  test('a tap on the body asks in the app and changes nothing', () async {
    final row = await synced('2026-11-26T18:00:00');
    final result = await handler.handle(null, payloadFor(row));
    expect(result.outcome, ReminderActionOutcome.openPrompt);
    expect(result.before!.title, 'Take pills');
    expect((await reload(row)).status, 'PENDING');
    expect(await handler.handle('', 'not a payload'), isA<ReminderActionResult>()
        .having((r) => r.outcome, 'outcome', ReminderActionOutcome.ignored));
  });

  group('repeating reminder', () {
    test('Done moves it to the next occurrence and stays pending', () async {
      final row = await synced('2026-11-26T18:00:00', interval: 'DAILY');
      final result = await handler.handle(ReminderActions.done, payloadFor(row));

      expect(result.outcome, ReminderActionOutcome.answered);
      final after = await reload(row);
      expect(after.remindAt, '2026-11-27T18:00:00');
      expect(after.dueDate, '2026-11-27');
      expect(after.status, 'PENDING');
      expect(after.lastOutcome, 'COMPLETED');
      expect(after.lastOutcomeAt, '2026-11-26T18:00:00');
      expect(after.startAt, '2026-11-26T18:00:00');

      expect(server.count('completeReminderOccurrence'), 1);
      expect(server.reminders[row.serverId]!['lastOutcomeAt'], '2026-11-26T18:00:00');
      expect(platform.scheduled[row.id]!.at, tz.TZDateTime(newYork, 2026, 11, 27, 18));
      expect(jsonDecode(platform.scheduled[row.id]!.payload!)['occurrence'], '2026-11-27T18:00:00');
    });

    test('a second answer for the same occurrence is ignored', () async {
      final row = await synced('2026-11-26T18:00:00', interval: 'WEEKLY');
      await handler.handle(ReminderActions.notDone, payloadFor(row));
      final again = await handler.handle(ReminderActions.notDone, payloadFor(row));
      expect(again.outcome, ReminderActionOutcome.ignored);
      expect((await reload(row)).remindAt, '2026-12-03T18:00:00');
      expect(server.count('completeReminderOccurrence'), 1);
    });

    test('a late Done for an occurrence caught up as missed is recorded', () async {
      final row = await synced('2026-11-26T18:00:00', interval: 'DAILY');
      final shown = payloadFor(row);
      // The app opened after it fired and nobody answered: catch-up.
      now = tz.TZDateTime(newYork, 2026, 11, 26, 18, 5);
      await scheduler.reconcile();
      expect((await reload(row)).lastOutcome, 'MISSED');

      final late = await handler.handle(ReminderActions.done, shown);
      expect(late.outcome, ReminderActionOutcome.answered);
      final after = await reload(row);
      expect(after.lastOutcome, 'COMPLETED');
      expect(after.remindAt, '2026-11-27T18:00:00', reason: 'no second advance');
    });
  });

  group('undo', () {
    test('restores a one-off to pending', () async {
      final row = await synced('2026-11-26T18:00:00');
      final result = await handler.handle(ReminderActions.done, payloadFor(row));
      await handler.undo(result);
      expect((await reload(row)).status, 'PENDING');
      expect(server.reminders[row.serverId]!['status'], 'PENDING');
    });

    test('puts a repeating reminder back on the answered occurrence', () async {
      // Answered in the app before its time (from the reminder sheet).
      now = tz.TZDateTime(newYork, 2026, 11, 26, 17, 50);
      final row = await synced('2026-11-26T18:00:00', interval: 'DAILY');
      final result = await handler.handle(ReminderActions.done, payloadFor(row));
      await handler.undo(result);
      final after = await reload(row);
      expect(after.remindAt, '2026-11-26T18:00:00');
      expect(after.startAt, '2026-11-26T18:00:00');
      expect(after.status, 'PENDING');
      expect(platform.scheduled[row.id]!.at, tz.TZDateTime(newYork, 2026, 11, 26, 18));
    });

    test('undoing an answer for a past occurrence leaves it unanswered (missed)', () async {
      final row = await synced('2026-11-26T18:00:00', interval: 'DAILY');
      final result = await handler.handle(ReminderActions.done, payloadFor(row));
      await handler.undo(result);
      final after = await reload(row);
      expect(after.remindAt, '2026-11-27T18:00:00', reason: 'catch-up moves past it again');
      expect(after.lastOutcome, 'MISSED');
      expect(after.lastOutcomeAt, '2026-11-26T18:00:00');
    });
  });

  test('errors are caught and reported as failed', () async {
    final row = await synced('2026-11-26T18:00:00');
    await database.close();
    final result = await handler.handle(ReminderActions.done, payloadFor(row));
    expect(result.outcome, ReminderActionOutcome.failed);
    database = AppDatabase.forTesting(NativeDatabase.memory()); // for tearDown
  });

  testWidgets('the in-app sheet returns the chosen answer and offers Undo', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(412, 892),
      builder: (_, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: Builder(builder: (c) {
          context = c;
          return const SizedBox.expand();
        })),
      ),
    ));

    final answer = showReminderAnswerSheet(context, 'Take pills');
    await tester.pumpAndSettle();
    expect(find.text('Did you take pills?'), findsOneWidget);
    expect(find.text('Not done'), findsOneWidget);
    expect(find.text('Snooze 10 min'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await answer, ReminderActions.done);

    showReminderAnswerSnackBar(
      ScaffoldMessenger.of(context),
      handler,
      const ReminderActionResult(ReminderActionOutcome.answered, actionId: ReminderActions.done),
    );
    await tester.pump();
    expect(find.text('Marked done ✓'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    showReminderAnswerSnackBar(
      ScaffoldMessenger.of(context),
      handler,
      const ReminderActionResult(ReminderActionOutcome.snoozed, actionId: ReminderActions.snooze),
    );
    await tester.pumpAndSettle();
    expect(find.text('Snoozed for 10 minutes'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
  });
}
