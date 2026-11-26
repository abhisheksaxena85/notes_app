import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_notification_platform.dart';
import 'support/fake_server.dart';

/// REM-03: the OS's scheduled notifications always match the reminders in
/// the database. Real in-memory database and repository, fake OS.
void main() {
  const userId = 42;
  late tz.Location newYork;
  late AppDatabase database;
  late OfflineSyncService sync;
  late ReminderRepo repo;
  late FakeNotificationPlatform platform;
  late NotificationService notifications;
  late ReminderScheduler scheduler;
  late tz.TZDateTime now;
  var signedIn = userId;

  setUpAll(() {
    tzdata.initializeTimeZones();
    newYork = tz.getLocation('America/New_York');
  });

  setUp(() {
    tz.setLocalLocation(newYork);
    now = tz.TZDateTime(newYork, 2026, 11, 26, 9);
    signedIn = userId;
    database = AppDatabase.forTesting(NativeDatabase.memory());
    final server = FakeServer();
    sync = OfflineSyncService(client: server, database: database);
    repo = ReminderRepo(client: server, database: database, syncService: sync);
    platform = FakeNotificationPlatform();
    notifications = NotificationService(platform: platform, supported: true, android: true);
    scheduler = ReminderScheduler(
      database: database,
      repo: repo,
      notifications: notifications,
      currentUserId: () => signedIn,
      now: () => now,
      use24h: () => false,
      debounce: const Duration(milliseconds: 5),
    );
  });

  tearDown(() async {
    await scheduler.dispose();
    await sync.dispose();
    await database.close();
  });

  Future<int> create(
    String title,
    String remindAt, {
    String interval = 'NONE',
    String category = 'Work',
  }) => repo.enqueueReminder(CreateReminderRequestDto(
    userId: userId,
    title: title,
    remindAt: remindAt,
    category: category,
    repeatInterval: interval,
  ));

  Map<String, dynamic> payloadOf(int id) =>
      jsonDecode(platform.scheduled[id]!.payload!) as Map<String, dynamic>;

  test('a new reminder is scheduled at its wall-clock time with its payload', () async {
    final id = await create('Call mom', '2026-11-26T18:00:00');
    await scheduler.reconcile();

    final scheduled = platform.scheduled[id]!;
    expect(scheduled.at, tz.TZDateTime(newYork, 2026, 11, 26, 18));
    expect(scheduled.title, 'Call mom');
    expect(scheduled.body, 'Due 6:00 PM · Work');
    expect(scheduled.details.android!.actions, hasLength(3));
    expect(payloadOf(id), {
      'v': 1,
      'type': 'reminder',
      'userId': userId,
      'localId': id,
      'serverId': null,
      'occurrence': '2026-11-26T18:00:00',
      'fireAt': scheduled.at.toIso8601String(),
    });
  });

  test('reconcile is idempotent', () async {
    await create('A', '2026-11-26T18:00:00');
    await scheduler.reconcile();
    await scheduler.reconcile();
    expect(platform.scheduleCalls, 1);
    expect(platform.cancelled, isEmpty);
  });

  test('editing the time reschedules the same notification', () async {
    final id = await create('A', '2026-11-26T18:00:00');
    await scheduler.reconcile();
    await repo.updateReminder(userId, UpdateReminderRequestDto(reminderId: -id, remindAt: '2026-11-27T07:30'));
    await scheduler.reconcile();

    expect(platform.scheduled.keys, [id]);
    expect(platform.scheduled[id]!.at, tz.TZDateTime(newYork, 2026, 11, 27, 7, 30));
    expect(payloadOf(id)['occurrence'], '2026-11-27T07:30:00');
  });

  test('deleting or completing a reminder cancels it', () async {
    final deleted = await create('Delete me', '2026-11-26T18:00:00');
    final completed = await create('Complete me', '2026-11-26T19:00:00');
    final kept = await create('Keep me', '2026-11-26T20:00:00');
    await scheduler.reconcile();
    expect(platform.scheduled.keys, unorderedEquals([deleted, completed, kept]));

    await repo.deleteReminder(userId, -deleted);
    await repo.updateReminderStatus(userId, -completed, 'COMPLETED');
    await scheduler.reconcile();

    expect(platform.scheduled.keys, [kept]);
    expect(platform.cancelled, unorderedEquals([deleted, completed]));
  });

  test('past one-off reminders are not scheduled', () async {
    await create('Yesterday', '2026-11-25T18:00:00');
    await create('Earlier today', '2026-11-26T08:59:00');
    await scheduler.reconcile();
    expect(platform.scheduled, isEmpty);
  });

  test('a snooze fires at the snooze time, then the reminder is unchanged', () async {
    final id = await create('Stretch', '2026-11-26T08:50:00');
    await repo.snoozeReminder(userId, id, now.add(const Duration(minutes: 10)));
    await scheduler.reconcile();

    final scheduled = platform.scheduled[id]!;
    expect(scheduled.at, tz.TZDateTime(newYork, 2026, 11, 26, 9, 10));
    expect(scheduled.body, startsWith('Snoozed · Due 8:50 AM'));
    expect(payloadOf(id)['occurrence'], '2026-11-26T08:50:00');
    expect((await database.getRemindersForUser(userId)).single.status, 'PENDING');
    expect(await database.getPendingMutations(userId), isEmpty,
        reason: 'a snooze is never sent to the server');

    // Once the snooze is over and unanswered, nothing fires again.
    now = tz.TZDateTime(newYork, 2026, 11, 26, 9, 11);
    await scheduler.reconcile();
    expect(platform.scheduled, isEmpty);
  });

  test('only the nearest 50 of 80 are scheduled; the 51st follows', () async {
    final ids = <int>[];
    for (var i = 0; i < 80; i++) {
      final day = 27 + i ~/ 24;
      final at = tz.TZDateTime(newYork, 2026, 11, day, i % 24);
      final remindAt = at.toIso8601String().substring(0, 19);
      ids.add(await create('R$i', remindAt));
    }
    await scheduler.reconcile();
    expect(platform.scheduled.keys, unorderedEquals(ids.take(50)));

    // The first one fires and is answered: the 51st takes its place.
    await repo.updateReminderStatus(userId, -ids.first, 'COMPLETED');
    await scheduler.reconcile();
    expect(platform.scheduled, hasLength(50));
    expect(platform.scheduled.keys, unorderedEquals(ids.skip(1).take(50)));
  });

  test('a time zone change keeps the wall-clock time and reschedules', () async {
    final id = await create('Standup', '2026-11-27T09:30:00');
    await scheduler.reconcile();
    expect(platform.scheduled[id]!.at.toUtc(), DateTime.utc(2026, 11, 27, 14, 30));

    platform.timezone = 'Europe/Berlin';
    now = tz.TZDateTime.from(now, tz.getLocation('Europe/Berlin'));
    await scheduler.onAppResumed();

    final moved = platform.scheduled[id]!;
    expect(moved.at.location.name, 'Europe/Berlin');
    expect((moved.at.hour, moved.at.minute), (9, 30));
    expect(moved.at.toUtc(), DateTime.utc(2026, 11, 27, 8, 30));
  });

  test('logout cancels reminders but leaves the digests', () async {
    await create('A', '2026-11-26T18:00:00');
    await create('B', '2026-11-27T18:00:00');
    await scheduler.reconcile();
    await notifications.schedule(
      id: 900001,
      at: tz.TZDateTime(newYork, 2026, 11, 27, 9),
      title: 'Plan your day',
      body: 'Digest',
      payload: '{"type":"digest","kind":"daily"}',
      channel: NotificationChannels.digests,
      withActions: false,
    );

    signedIn = 0;
    await scheduler.cancelAllReminders();
    expect(platform.scheduled.keys, [900001]);

    // Nothing is scheduled for nobody.
    await scheduler.reconcile();
    expect(platform.scheduled.keys, [900001]);
  });

  test('nothing is scheduled without permission or on unsupported platforms', () async {
    await create('A', '2026-11-26T18:00:00');
    platform.enabled = false;
    await scheduler.reconcile();
    expect(platform.scheduled, isEmpty);

    platform.enabled = true;
    final off = ReminderScheduler(
      database: database,
      repo: repo,
      notifications: NotificationService(platform: platform, supported: false),
      currentUserId: () => userId,
      now: () => now,
    );
    await off.reconcile();
    expect(platform.scheduled, isEmpty);
  });

  test('repeating reminders missed while closed catch up without a burst', () async {
    // DAILY 08:00, last pending occurrence three days ago.
    final id = await create('Vitamins', '2026-11-23T08:00:00', interval: 'DAILY', category: '');
    await scheduler.reconcile();

    final row = (await database.getRemindersForUser(userId)).single;
    expect(row.remindAt, '2026-11-27T08:00:00', reason: 'next future 08:00 (now is 09:00)');
    expect(row.startAt, '2026-11-23T08:00:00', reason: 'the anchor is kept');
    expect(row.status, 'PENDING');
    expect(row.lastOutcome, 'MISSED');
    expect(row.lastOutcomeAt, '2026-11-23T08:00:00');
    expect(row.dueDate, '2026-11-27');

    expect(platform.scheduled.keys, [id]);
    expect(platform.scheduleCalls, 1, reason: 'no flood of old notifications');
    expect(platform.scheduled[id]!.at, tz.TZDateTime(newYork, 2026, 11, 27, 8));
    expect(platform.scheduled[id]!.body, 'Due 8:00 AM · Repeats daily');
  });

  test('start() follows the watch stream, session changes and permission', () async {
    final permission = ValueNotifier(const NotificationStatus(NotificationPermission.denied));
    final sessions = StreamController<int>.broadcast(sync: true);
    platform.enabled = false;
    scheduler.start(userChanges: sessions.stream, permission: permission);

    final id = await create('Watched', '2026-11-26T18:00:00');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(platform.scheduled, isEmpty, reason: 'no permission yet');

    platform.enabled = true;
    permission.value = const NotificationStatus(NotificationPermission.granted);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(platform.scheduled.keys, [id]);

    await repo.updateReminder(userId, UpdateReminderRequestDto(reminderId: -id, title: 'Renamed'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(platform.scheduled[id]!.title, 'Renamed');

    // Signed out: changes no longer reconcile.
    signedIn = 0;
    sessions.add(0);
    await repo.updateReminder(userId, UpdateReminderRequestDto(reminderId: -id, title: 'Ignored'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(platform.scheduled[id]!.title, 'Renamed');
    await sessions.close();
  });

  test('payload parsing ignores anything that is not a reminder', () {
    expect(ReminderPayload.tryParse(null), isNull);
    expect(ReminderPayload.tryParse('not json'), isNull);
    expect(ReminderPayload.tryParse('{"type":"digest"}'), isNull);
    expect(ReminderPayload.tryParse('{"v":2,"type":"reminder","userId":1,"localId":2,"occurrence":"x"}'),
        isNull);
    final parsed = ReminderPayload.tryParse(const ReminderPayload(
      userId: 1,
      localId: 2,
      serverId: 3,
      occurrence: '2026-11-26T18:00:00',
      fireAt: 'x',
    ).encode())!;
    expect((parsed.userId, parsed.localId, parsed.serverId, parsed.occurrence),
        (1, 2, 3, '2026-11-26T18:00:00'));
  });
}
