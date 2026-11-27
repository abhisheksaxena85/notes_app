import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/utils/services/home_widgets/widget_links.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_widget_host.dart';

/// W-01: what the home-screen widgets get from Drift.
void main() {
  const userId = 7;
  late tz.Location newYork;
  late AppDatabase database;
  late tz.TZDateTime now;

  setUpAll(() {
    tzdata.initializeTimeZones();
    newYork = tz.getLocation('America/New_York');
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    // Friday 27 November 2026, 10:00 in New York.
    now = tz.TZDateTime(newYork, 2026, 11, 27, 10);
  });

  tearDown(() => database.close());

  Future<int> task(
    String title, {
    String? date,
    String? time,
    String status = 'PENDING',
    int? serverId,
    int user = userId,
  }) => database.into(database.cachedTasks).insert(CachedTasksCompanion.insert(
    userId: user,
    title: title,
    serverId: Value(serverId),
    dueDate: Value(date),
    dueTime: Value(time),
    status: Value(status),
    isCompleted: Value(status == 'COMPLETED'),
  ));

  Future<int> reminder(
    String title,
    String remindAt, {
    String repeat = 'NONE',
    String status = 'PENDING',
    String? startAt,
    String? snoozedUntil,
    int? serverId,
  }) => database.into(database.cachedReminders).insert(CachedRemindersCompanion.insert(
    userId: userId,
    title: title,
    remindAt: remindAt,
    serverId: Value(serverId),
    repeatInterval: Value(repeat),
    status: Value(status),
    startAt: Value(startAt ?? remindAt),
    snoozedUntil: Value(snoozedUntil),
  ));

  Future<WidgetSnapshot> build() async => WidgetSnapshot.build(
    tasks: await database.getTasksForUser(userId),
    reminders: await database.getRemindersForUser(userId),
    now: now,
  );

  group('tasks', () {
    test('overdue and due today first by due moment, then undated; others left out', () async {
      await task('Undated A');
      await task('Today 18:00', date: '2026-11-27', time: '18:00');
      await task('Tomorrow', date: '2026-11-28', time: '09:00');
      await task('Yesterday', date: '2026-11-26', time: '15:00');
      await task('Today no time', date: '2026-11-27');
      await task('Today 08:00', date: '2026-11-27', time: '08:00');
      await task('Done today', date: '2026-11-27', time: '11:00', status: 'COMPLETED');
      await task('Missed', date: '2026-11-25', status: 'MISSED');
      await task('Undated B');
      await task('Another user', date: '2026-11-27', user: 99);

      final snapshot = await build();

      expect(snapshot.tasks.map((t) => t.title), [
        'Yesterday',
        'Today 08:00',
        'Today 18:00',
        'Today no time',
        'Undated A',
        'Undated B',
      ]);
      expect(snapshot.taskCount, 6);
    });

    test('the overdue flag', () async {
      await task('Yesterday no time', date: '2026-11-26');
      await task('Earlier today', date: '2026-11-27', time: '09:59');
      await task('Later today', date: '2026-11-27', time: '10:01');
      await task('Today no time', date: '2026-11-27');
      await task('Undated');

      final byTitle = {for (final t in (await build()).tasks) t.title: t};

      expect(byTitle['Yesterday no time']!.overdue, isTrue);
      expect(byTitle['Earlier today']!.overdue, isTrue);
      expect(byTitle['Later today']!.overdue, isFalse);
      expect(byTitle['Today no time']!.overdue, isFalse);
      expect(byTitle['Today no time']!.hasTime, isFalse);
      expect(byTitle['Undated']!.overdue, isFalse);
      expect(byTitle['Undated']!.dueAt, isNull);
      expect(byTitle['Later today']!.dueAt, tz.TZDateTime(newYork, 2026, 11, 27, 10, 1));
    });

    test('ids are the app item ids: server id, or minus the local id', () async {
      final local = await task('Local only');
      await task('Synced', serverId: 501);

      final ids = {for (final t in (await build()).tasks) t.title: t.id};

      expect(ids['Local only'], -local);
      expect(ids['Synced'], 501);
    });

    test('at most 12 items, with the full count', () async {
      for (var i = 0; i < 15; i++) {
        await task('Task $i');
      }

      final snapshot = await build();

      expect(snapshot.tasks, hasLength(WidgetSnapshot.maxTasks));
      expect(snapshot.taskCount, 15);
    });
  });

  group('reminders', () {
    test('soonest first, answered and past one-offs left out, at most 5', () async {
      await reminder('Past one-off', '2026-11-27T09:00:00');
      await reminder('Done', '2026-11-27T11:00:00', status: 'COMPLETED');
      await reminder('Evening', '2026-11-27T18:00:00');
      await reminder('Noon', '2026-11-27T12:00:00');
      for (var day = 1; day <= 5; day++) {
        await reminder('Later $day', '2026-12-0${day}T09:00:00');
      }

      final reminders = (await build()).reminders;

      expect(reminders.map((r) => r.title), ['Noon', 'Evening', 'Later 1', 'Later 2', 'Later 3']);
      expect(reminders.first.fireAt, tz.TZDateTime(newYork, 2026, 11, 27, 12));
      expect(reminders.first.occurrence, '2026-11-27T12:00:00');
    });

    test('a repeating reminder that was not caught up fires at its next occurrence', () async {
      // Daily at 08:00 since Monday; the app last ran on Tuesday.
      await reminder('Pills', '2026-11-24T08:00:00', repeat: 'DAILY', startAt: '2026-11-23T08:00:00');

      final reminders = (await build()).reminders;

      expect(reminders.first.occurrence, '2026-11-28T08:00:00');
      expect(reminders.first.fireAt, tz.TZDateTime(newYork, 2026, 11, 28, 8));
      expect(reminders.first.repeat, 'DAILY');
    });

    test('a repeating series fills the following slots, so the widget can roll over', () async {
      await reminder('Stand-up', '2026-11-27T11:00:00', repeat: 'DAILY');
      await reminder('Dentist', '2026-11-28T15:00:00');

      final reminders = (await build()).reminders;

      expect(reminders.map((r) => '${r.title} ${r.occurrence}'), [
        'Stand-up 2026-11-27T11:00:00',
        'Stand-up 2026-11-28T11:00:00',
        'Dentist 2026-11-28T15:00:00',
        'Stand-up 2026-11-29T11:00:00',
        'Stand-up 2026-11-30T11:00:00',
      ]);
    });

    test('a snooze wins over the scheduled time and keeps the occurrence', () async {
      final snoozeEnd = tz.TZDateTime(newYork, 2026, 11, 27, 10, 5).toUtc();
      await reminder('Call back', '2026-11-27T09:55:00', snoozedUntil: snoozeEnd.toIso8601String());
      await reminder('Expired snooze', '2026-11-27T11:00:00',
          snoozedUntil: tz.TZDateTime(newYork, 2026, 11, 27, 9).toUtc().toIso8601String());

      final reminders = (await build()).reminders;

      expect(reminders.first.title, 'Call back');
      expect(reminders.first.snoozed, isTrue);
      expect(reminders.first.fireAt.millisecondsSinceEpoch, snoozeEnd.millisecondsSinceEpoch);
      expect(reminders.first.occurrence, '2026-11-27T09:55:00');
      // An expired snooze falls back to the scheduled time.
      expect(reminders[1].title, 'Expired snooze');
      expect(reminders[1].snoozed, isFalse);
      expect(reminders[1].fireAt, tz.TZDateTime(newYork, 2026, 11, 27, 11));
    });

    test('a snoozed repeating occurrence is followed by the next one, not a past one', () async {
      final snoozeEnd = tz.TZDateTime(newYork, 2026, 11, 27, 10, 5).toUtc();
      await reminder('Water', '2026-11-27T09:55:00',
          repeat: 'DAILY', snoozedUntil: snoozeEnd.toIso8601String());

      final reminders = (await build()).reminders;

      expect(reminders[0].occurrence, '2026-11-27T09:55:00');
      expect(reminders[1].occurrence, '2026-11-28T09:55:00');
    });
  });

  test('the JSON the native widgets read', () async {
    final id = await task('Today', date: '2026-11-27', time: '18:00');
    await reminder('Stretch', '2026-11-27T18:00:00', repeat: 'WEEKLY', serverId: 12);

    final json = jsonDecode((await build()).encode()) as Map<String, dynamic>;

    expect(json['v'], 1);
    expect(json['loggedIn'], isTrue);
    expect(json['tasks'], {
      'count': 1,
      'items': [
        {
          'id': -id,
          'title': 'Today',
          'dueAt': tz.TZDateTime(newYork, 2026, 11, 27, 18).millisecondsSinceEpoch,
          'hasTime': true,
          'overdue': false,
        },
      ],
    });
    expect((json['reminders'] as List).first, {
      'id': 12,
      'title': 'Stretch',
      'fireAt': tz.TZDateTime(newYork, 2026, 11, 27, 18).millisecondsSinceEpoch,
      'occurrence': '2026-11-27T18:00:00',
      'repeat': 'WEEKLY',
      'snoozed': false,
    });
  });

  group('WidgetSnapshotService', () {
    late FakeWidgetHost host;
    var signedIn = userId;

    WidgetSnapshotService service() => WidgetSnapshotService(
      database: database,
      host: host,
      currentUserId: () => signedIn,
      now: () => now,
      debounce: const Duration(milliseconds: 5),
    );

    setUp(() {
      host = FakeWidgetHost();
      signedIn = userId;
    });

    test('signed out: the logged-out snapshot, nothing scheduled', () async {
      await task('Secret', date: '2026-11-27');
      signedIn = 0;

      await service().refresh();

      final json = host.snapshot!;
      expect(json['loggedIn'], isFalse);
      expect(json['tasks'], {'count': 0, 'items': []});
      expect(json['reminders'], isEmpty);
      expect(host.updates, 1);
      expect(host.scheduled, isEmpty);
    });

    test('logout clears what the previous user saw', () async {
      await task('Mine', date: '2026-11-27');
      final widgets = service();
      await widgets.refresh();
      expect((host.snapshot!['tasks'] as Map)['count'], 1);

      signedIn = 0;
      await widgets.showLoggedOut();

      expect(host.snapshot!['loggedIn'], isFalse);
      await widgets.dispose();
    });

    test('schedules an Android refresh just after each upcoming reminder', () async {
      await reminder('Noon', '2026-11-27T12:00:00');

      await service().refresh();

      expect(host.scheduled, [
        tz.TZDateTime(newYork, 2026, 11, 27, 12).add(const Duration(seconds: 1)),
      ]);
    });

    test('follows changes to the rows, debounced', () async {
      final widgets = service()..start();
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final before = host.updates;

      await task('New', date: '2026-11-27');
      await task('Newer', date: '2026-11-27');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(host.updates, before + 1);
      expect((host.snapshot!['tasks'] as Map)['count'], 2);
      await widgets.dispose();
    });

    test('does nothing where widgets are unsupported', () async {
      host = FakeWidgetHost(supported: false);

      await service().refresh();

      expect(host.snapshot, isNull);
      expect(host.updates, 0);
    });
  });

  group('WidgetLink.parse', () {
    test('known links', () {
      expect(WidgetLink.parse(Uri.parse('daymark://task/-4?homeWidget')), const OpenTaskLink(-4));
      expect(WidgetLink.parse(Uri.parse('daymark://reminder/12')), const OpenReminderLink(12));
      expect(WidgetLink.parse(Uri.parse('daymark://quick-add-task')), isA<QuickAddTaskLink>());
      expect(WidgetLink.parse(Uri.parse('daymark://new-reminder?homeWidget')), isA<NewReminderLink>());
      expect(WidgetLink.parse(Uri.parse('daymark://workspace')), isA<WorkspaceLink>());
    });

    test('anything else is ignored', () {
      expect(WidgetLink.parse(null), isNull);
      expect(WidgetLink.parse(Uri.parse('https://task/4')), isNull);
      expect(WidgetLink.parse(Uri.parse('daymark://task/abc')), isNull);
      expect(WidgetLink.parse(Uri.parse('daymark://unknown')), isNull);
    });
  });
}
