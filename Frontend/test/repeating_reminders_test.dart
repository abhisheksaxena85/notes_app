import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/response/item_status.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_scheduler.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/screens/home/widgets/item_status_sheet.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_item_card.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_notification_platform.dart';
import 'support/fake_server.dart';

/// REM-05: repeating reminders move to their next occurrence.
void main() {
  const userId = 42;
  late AppDatabase database;
  late FakeServer server;
  late OfflineSyncService sync;
  late ReminderRepo repo;

  setUpAll(tzdata.initializeTimeZones);

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

  Future<CachedReminder> create(String remindAt, String interval, {bool upload = true}) async {
    final id = await repo.enqueueReminder(CreateReminderRequestDto(
      userId: userId,
      title: 'Pay rent',
      remindAt: remindAt,
      repeatInterval: interval,
    ));
    if (upload) {
      sync.setUserId(userId);
      await sync.requestSync();
    }
    return (await database.getReminderRow(userId, id))!;
  }

  Future<CachedReminder> reload(CachedReminder row) async =>
      (await database.getReminderRow(userId, row.id))!;

  test('monthly from Jan 31 goes to Feb 28, then back to Mar 31', () async {
    final row = await create('2026-01-31T09:00:00', 'MONTHLY');
    await repo.answerCurrentOccurrence(userId, row.serverId!, 'COMPLETED');
    expect((await reload(row)).remindAt, '2026-02-28T09:00:00');
    await repo.answerCurrentOccurrence(userId, row.serverId!, 'MISSED');
    final march = await reload(row);
    expect(march.remindAt, '2026-03-31T09:00:00');
    expect(march.dueDate, '2026-03-31');
    expect(march.startAt, '2026-01-31T09:00:00');
    expect(march.lastOutcome, 'MISSED');
    expect(march.lastOutcomeAt, '2026-02-28T09:00:00');
    expect(march.status, 'PENDING');
  });

  test('a synced reminder queues complete-occurrence with the answered occurrence', () async {
    final row = await create('2026-11-26T08:00:00', 'DAILY');
    server.onRequest = (_, _) => throw FakeServer.offline();
    await repo.answerCurrentOccurrence(userId, row.serverId!, 'COMPLETED');

    final mutation = (await database.getPendingMutations(userId)).single;
    expect(mutation.op, 'occurrence');
    expect(jsonDecode(mutation.payload), {'occurrence': '2026-11-26T08:00:00', 'outcome': 'COMPLETED'});

    server.onRequest = null;
    await sync.requestSync();
    expect(server.count('completeReminderOccurrence'), 1);
    expect(await database.getPendingMutations(userId), isEmpty);
  });

  test('a never-sent reminder is created already on its next occurrence', () async {
    final row = await create('2026-11-26T08:00:00', 'WEEKLY', upload: false);
    await repo.answerCurrentOccurrence(userId, -row.id, 'COMPLETED');
    expect(await database.getPendingMutations(userId), isEmpty, reason: 'merged into the create');

    sync.setUserId(userId);
    await sync.requestSync();
    final created = server.reminders.values.single;
    expect(created['remindAt'], '2026-12-03T08:00:00');
    expect(created['startAt'], '2026-11-26T08:00:00');
    expect(server.count('completeReminderOccurrence'), 0);
  });

  test('a one-off reminder just takes the outcome as status', () async {
    final row = await create('2026-11-26T08:00:00', 'NONE');
    await repo.answerCurrentOccurrence(userId, row.serverId!, 'MISSED');
    expect((await reload(row)).status, 'MISSED');
    expect((await reload(row)).remindAt, '2026-11-26T08:00:00');
  });

  test('repeats catch up even where notifications are unsupported or off', () async {
    final ny = tz.getLocation('America/New_York');
    tz.setLocalLocation(ny);
    final row = await create('2026-11-20T08:00:00', 'DAILY', upload: false);
    final platform = FakeNotificationPlatform()..enabled = false;
    for (final supported in [false, true]) {
      final scheduler = ReminderScheduler(
        database: database,
        repo: repo,
        notifications: NotificationService(platform: platform, supported: supported),
        currentUserId: () => userId,
        now: () => tz.TZDateTime(ny, 2026, 11, 26 + (supported ? 1 : 0), 9),
      );
      await scheduler.reconcile();
      await scheduler.dispose();
    }
    expect((await reload(row)).remindAt, '2026-11-28T08:00:00');
    expect((await reload(row)).lastOutcome, 'MISSED');
    expect(platform.scheduled, isEmpty);
  });

  test('repeating choices map to occurrence outcomes', () {
    expect(RepeatingChoice.outcomeOf(RepeatingChoice.doneToday), 'COMPLETED');
    expect(RepeatingChoice.outcomeOf(RepeatingChoice.missedToday), 'MISSED');
    expect(RepeatingChoice.outcomeOf(RepeatingChoice.stop), isNull);
    expect(RepeatingChoice.outcomeOf('COMPLETED'), isNull);
  });

  Widget host(Widget Function(BuildContext) child) => ScreenUtilInit(
    designSize: const Size(412, 892),
    builder: (_, _) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Builder(builder: child)),
    ),
  );

  testWidgets('the status sheet offers done/missed today and stop for repeats', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(host((c) {
      context = c;
      return const SizedBox.expand();
    }));
    final choice = showItemStatusSheet(context, currentStatus: 'PENDING', repeating: true);
    await tester.pumpAndSettle();
    expect(find.text('Done for today'), findsOneWidget);
    expect(find.text('Missed today'), findsOneWidget);
    expect(find.text('Stop repeating'), findsOneWidget);
    expect(find.text('Completed'), findsNothing);
    await tester.tap(find.text('Missed today'));
    await tester.pumpAndSettle();
    expect(await choice, RepeatingChoice.missedToday);
  });

  testWidgets('a repeating card shows the last answer and answers today on tap', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(host((context) => reminderItemCard(
      context: context,
      reminder: ReminderItem(
        reminderId: 1,
        title: 'Vitamins',
        remindAt: '2099-11-27T08:00:00',
        repeatInterval: 'DAILY',
        lastOutcome: 'COMPLETED',
        lastOutcomeAt: '2099-11-26T08:00:00',
      ),
      onStatusChange: changes.add,
    )));
    expect(find.text('Last: done ✓ (Nov 26)'), findsOneWidget);
    await tester.tap(find.byType(AnimatedContainer).first);
    expect(changes, [RepeatingChoice.doneToday]);
  });
}
