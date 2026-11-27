import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/home_widgets/widget_actions.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';
import 'package:notes_app/utils/services/reminder_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_notification_platform.dart';
import 'support/fake_server.dart';
import 'support/fake_widget_host.dart';

/// W-02: ticking a task and answering a reminder on a widget, local first
/// plus the outbox, idempotent. In-memory database, fake server, fake OS.
void main() {
  const userId = 42;
  late tz.Location newYork;
  late AppDatabase database;
  late FakeServer server;
  late OfflineSyncService sync;
  late TaskRepo tasks;
  late ReminderRepo reminders;
  late FakeNotificationPlatform platform;
  late ReminderScheduler scheduler;
  late FakeWidgetHost host;
  late WidgetActionHandler handler;
  late tz.TZDateTime now;
  var signedIn = userId;

  setUpAll(() {
    tzdata.initializeTimeZones();
    newYork = tz.getLocation('America/New_York');
  });

  setUp(() {
    tz.setLocalLocation(newYork);
    now = tz.TZDateTime(newYork, 2026, 11, 27, 9);
    signedIn = userId;
    database = AppDatabase.forTesting(NativeDatabase.memory());
    server = FakeServer();
    sync = OfflineSyncService(client: server, database: database);
    tasks = TaskRepo(client: server, database: database, syncService: sync);
    reminders = ReminderRepo(client: server, database: database, syncService: sync);
    platform = FakeNotificationPlatform();
    scheduler = ReminderScheduler(
      database: database,
      repo: reminders,
      notifications: NotificationService(platform: platform, supported: true, android: true),
      currentUserId: () => signedIn,
      now: () => now,
      use24h: () => false,
    );
    Future<void> push() {
      sync.setUserId(userId);
      return sync.requestSync();
    }

    host = FakeWidgetHost();
    handler = WidgetActionHandler(
      database: database,
      taskRepo: tasks,
      scheduler: scheduler,
      reminderActions: ReminderActionHandler(
        database: database,
        repo: reminders,
        scheduler: scheduler,
        currentUserId: () => signedIn,
        pushChanges: push,
        now: () => now,
      ),
      widgets: WidgetSnapshotService(
        database: database,
        host: host,
        currentUserId: () => signedIn,
        now: () => now,
      ),
      currentUserId: () => signedIn,
      pushChanges: push,
    );
  });

  tearDown(() async {
    await scheduler.dispose();
    await sync.dispose();
    await database.close();
  });

  Future<int> newTask(String title, {String? date = '2026-11-27'}) async {
    final localId = await tasks.enqueueTask(
      CreateTaskRequestDto(userId: userId, title: title, dueDate: date),
    );
    await sync.requestSync();
    return localId;
  }

  Future<CachedTask> taskRow(int localId) async =>
      (await database.getTasksForUser(userId)).firstWhere((t) => t.id == localId);

  Future<CachedReminder> newReminder(String remindAt, {String interval = 'NONE'}) async {
    final localId = await reminders.enqueueReminder(CreateReminderRequestDto(
      userId: userId,
      title: 'Stretch',
      remindAt: remindAt,
      repeatInterval: interval,
    ));
    sync.setUserId(userId);
    await sync.requestSync();
    return (await database.getReminderRow(userId, localId))!;
  }

  Uri toggle(int id) => Uri.parse('daymark://widget/toggle-task?id=$id');
  Uri done(int id, String occurrence) => Uri(
    scheme: 'daymark',
    host: 'widget',
    path: '/reminder-done',
    queryParameters: {'id': '$id', 'occurrence': occurrence},
  );

  group('toggle-task', () {
    test('completes the task locally, syncs it and redraws the widget with it ticked', () async {
      sync.setUserId(userId);
      final localId = await newTask('Buy milk');
      final serverId = (await taskRow(localId)).serverId!;

      final outcome = await handler.handle(toggle(serverId));

      expect(outcome, WidgetActionOutcome.applied);
      final row = await taskRow(localId);
      expect(row.status, 'COMPLETED');
      expect(row.isCompleted, isTrue);
      expect(server.tasks[serverId]!['status'], 'COMPLETED');
      final items = (host.snapshot!['tasks'] as Map)['items'] as List;
      expect(items.single['doneAt'], now.millisecondsSinceEpoch);
      expect((host.snapshot!['tasks'] as Map)['count'], 0);
    });

    test('works offline: the change waits in the outbox', () async {
      sync.setUserId(userId);
      final localId = await newTask('Offline');
      server.onRequest = (call, request) => throw FakeServer.offline();

      final outcome = await handler.handle(toggle((await taskRow(localId)).serverId!));

      expect(outcome, WidgetActionOutcome.applied);
      expect((await taskRow(localId)).status, 'COMPLETED');
      expect(await database.countUnsyncedChanges(userId), 1);
    });

    test('a local-only task is found by minus its local id', () async {
      // Never synced: no server id yet.
      final localId = await tasks.enqueueTask(
        CreateTaskRequestDto(userId: userId, title: 'Local', dueDate: '2026-11-27'),
      );

      expect(await handler.handle(toggle(-localId)), WidgetActionOutcome.applied);
      expect((await taskRow(localId)).status, 'COMPLETED');
    });

    test('is idempotent: a second tap does not undo the first', () async {
      sync.setUserId(userId);
      final localId = await newTask('Twice');
      final id = (await taskRow(localId)).serverId!;

      await handler.handle(toggle(id));
      final calls = server.count('toggleTaskStatus');
      final second = await handler.handle(toggle(id));

      expect(second, WidgetActionOutcome.ignored);
      expect((await taskRow(localId)).status, 'COMPLETED');
      expect(server.count('toggleTaskStatus'), calls);
    });

    test('ignored for a deleted task or when signed out', () async {
      sync.setUserId(userId);
      final localId = await newTask('Gone');
      final id = (await taskRow(localId)).serverId!;
      await tasks.deleteTask(userId, id);
      expect(await handler.handle(toggle(id)), WidgetActionOutcome.ignored);

      final other = await newTask('Signed out');
      signedIn = 0;
      expect(await handler.handle(toggle(-other)), WidgetActionOutcome.ignored);
      signedIn = userId;
      expect((await taskRow(other)).status, 'PENDING');
      // The signed-out widget shows the logged-out state.
      expect(host.snapshot!['loggedIn'], isFalse);
    });
  });

  group('reminder-done', () {
    test('a one-off becomes COMPLETED and its notification is cancelled', () async {
      final row = await newReminder('2026-11-27T18:00:00');
      await scheduler.reconcile();
      expect(platform.scheduled, contains(row.id));

      final outcome = await handler.handle(done(row.serverId!, '2026-11-27T18:00:00'));

      expect(outcome, WidgetActionOutcome.applied);
      expect((await database.getReminderRow(userId, row.id))!.status, 'COMPLETED');
      expect(server.reminders[row.serverId!]!['status'], 'COMPLETED');
      expect(platform.scheduled, isNot(contains(row.id)));
      expect(host.snapshot!['reminders'], isEmpty);
    });

    test('a repeating reminder moves to its next occurrence', () async {
      final row = await newReminder('2026-11-27T18:00:00', interval: 'DAILY');

      await handler.handle(done(row.serverId!, '2026-11-27T18:00:00'));

      final after = (await database.getReminderRow(userId, row.id))!;
      expect(after.status, 'PENDING');
      expect(after.remindAt, '2026-11-28T18:00:00');
      expect(after.lastOutcome, 'COMPLETED');
      final first = (host.snapshot!['reminders'] as List).first;
      expect(first['occurrence'], '2026-11-28T18:00:00');
    });

    test('is idempotent by occurrence', () async {
      final row = await newReminder('2026-11-27T18:00:00', interval: 'DAILY');
      final link = done(row.serverId!, '2026-11-27T18:00:00');

      await handler.handle(link);
      final second = await handler.handle(link);

      expect(second, WidgetActionOutcome.ignored);
      expect((await database.getReminderRow(userId, row.id))!.remindAt, '2026-11-28T18:00:00');
    });

    test('a repeat the app had not caught up yet answers the occurrence the widget shows', () async {
      // Daily at 08:00; stored occurrence is two days old (app not opened).
      final row = await newReminder('2026-11-25T08:00:00', interval: 'DAILY');
      final shown = WidgetSnapshot.nextFire(row, now)!;
      // It's 09:00 on the 27th: the widget shows tomorrow's 08:00.
      expect(shown.occurrence, '2026-11-28T08:00:00');

      final outcome = await handler.handle(done(row.serverId!, shown.occurrence));

      expect(outcome, WidgetActionOutcome.applied);
      final after = (await database.getReminderRow(userId, row.id))!;
      expect(after.remindAt, '2026-11-29T08:00:00');
      expect(after.lastOutcome, 'COMPLETED');
      expect(after.lastOutcomeAt, '2026-11-28T08:00:00');
    });

    test('ignored for an unknown reminder or a bad link', () async {
      expect(await handler.handle(done(999, '2026-11-27T18:00:00')), WidgetActionOutcome.ignored);
      expect(
        await handler.handle(Uri.parse('daymark://widget/reminder-done?id=3&occurrence=soon')),
        WidgetActionOutcome.ignored,
      );
      expect(await handler.handle(Uri.parse('daymark://widget/explode?id=3')), WidgetActionOutcome.ignored);
      expect(await handler.handle(null), WidgetActionOutcome.ignored);
    });
  });

  test('WidgetAction.parse', () {
    expect(WidgetAction.parse(Uri.parse('daymark://widget/toggle-task?id=-5')), isA<ToggleTaskAction>());
    final reminder = WidgetAction.parse(
      Uri.parse('daymark://widget/reminder-done?id=7&occurrence=2026-11-27T18%3A00%3A00'),
    );
    expect(reminder, isA<ReminderDoneAction>());
    expect((reminder! as ReminderDoneAction).occurrence, '2026-11-27T18:00:00');
    expect(WidgetAction.parse(Uri.parse('daymark://widget/import-inbox')), isA<ImportInboxAction>());
    expect(WidgetAction.parse(Uri.parse('daymark://widget/toggle-task')), isNull);
    expect(WidgetAction.parse(Uri.parse('daymark://task/4')), isNull);
  });
}
