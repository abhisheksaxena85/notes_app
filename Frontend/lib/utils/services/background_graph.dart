import 'dart:developer';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/secure_storage/token_store.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/notification_background.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';
import 'package:notes_app/utils/services/reminder_scheduler.dart';

/// FIX-02: the light graph, enough to add or change tasks: preferences, the
/// database, the task repo and the sync service. No notifications, reminder
/// scheduler or reminder repo, so nothing that touches the notification
/// plugin can stop the widget's quick add from opening.
class TaskGraph {
  /// The user the app had signed in when the action started (0 = nobody).
  final int userId;
  final AppDatabase database;
  final OfflineSyncService sync;
  final TaskRepo taskRepo;

  TaskGraph({
    required this.userId,
    required this.database,
    required this.sync,
    required this.taskRepo,
  });

  /// Reads the signed-in user and opens the database, API client, sync and
  /// task repo the way the app does.
  static Future<TaskGraph> open() async {
    final userId = await _storedUserId();
    // The widget snapshot ("today", "overdue") needs tz.local. This only
    // loads the zone database and reads the device zone (UTC if it can't);
    // it doesn't touch the notification plugin.
    await NotificationService().initTimezone();
    final (database, client, sync) = _openData();
    return TaskGraph(
      userId: userId,
      database: database,
      sync: sync,
      taskRepo: TaskRepo(client: client, database: database, syncService: sync),
    );
  }

  Future<void> close() async {
    try {
      // Lets an upload that is still running finish, but not forever.
      await sync.dispose().timeout(const Duration(seconds: 20));
    } catch (error) {
      log('Background sync did not finish: $error');
    }
    await database.close();
  }
}

/// The main isolate may have changed the session since this isolate last
/// read the preferences (they are cached per isolate).
Future<int> _storedUserId() async {
  await Preference.init();
  await Preference.pref.reload();
  return SessionService.storedUserId(Preference());
}

(AppDatabase, ApiClient, OfflineSyncService) _openData() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // Shared across isolates: one database isolate for the app and this one.
  // Lazy: nothing connects until the first query.
  final database = AppDatabase();
  // SEC-02: its own Dio with the auth interceptor, reading the token the
  // app saved (a fresh TokenStore, so nothing cached from an older
  // session). A 401 here only fails the upload: the change stays queued
  // and the app signs the user out on its next request.
  final client = ApiClient(dioClient: DioClient.create(tokenStore: TokenStore.platform()));
  // No connectivity service: nothing listens or retries in this isolate.
  final sync = OfflineSyncService(client: client, database: database);
  return (database, client, sync);
}

/// The minimum a background isolate needs to change the user's items the
/// way the app does (REM-04 notification actions, W-02 widget actions): no
/// connectivity listener, no sync loop or retry timers, no Riverpod, no
/// get_it. Built per action and closed after.
class BackgroundGraph {
  /// The user the app had signed in when the action started (0 = nobody).
  final int userId;
  final AppDatabase database;
  final OfflineSyncService sync;
  final TaskRepo taskRepo;
  final ReminderRepo reminderRepo;
  final ReminderScheduler scheduler;
  final ReminderActionHandler reminderActions;

  BackgroundGraph._(
    this.userId,
    this.database,
    this.sync,
    this.taskRepo,
    this.reminderRepo,
    this.scheduler,
    this.reminderActions,
  );

  static Future<BackgroundGraph> open() async {
    final userId = await _storedUserId();
    final (database, client, sync) = _openData();
    final taskRepo = TaskRepo(client: client, database: database, syncService: sync);
    final reminderRepo = ReminderRepo(client: client, database: database, syncService: sync);

    // The plugin must be initialised in this isolate before scheduling; the
    // same callbacks keep the registration as the app made it. This also
    // loads the time zone database and sets tz.local.
    final notifications = NotificationService();
    await notifications.init(
      onForegroundResponse: (_) {},
      onBackgroundResponse: notificationTapBackground,
    );
    final scheduler = ReminderScheduler(
      database: database,
      repo: reminderRepo,
      notifications: notifications,
      currentUserId: () => userId,
    );
    final reminderActions = ReminderActionHandler(
      database: database,
      repo: reminderRepo,
      scheduler: scheduler,
      currentUserId: () => userId,
      pushChanges: () {
        sync.setUserId(userId);
        return sync.requestSync();
      },
    );
    return BackgroundGraph._(
      userId,
      database,
      sync,
      taskRepo,
      reminderRepo,
      scheduler,
      reminderActions,
    );
  }

  Future<void> close() async {
    try {
      // Lets an upload that is still running finish, but not forever.
      await sync.dispose().timeout(const Duration(seconds: 20));
    } catch (error) {
      log('Background sync did not finish: $error');
    }
    await scheduler.dispose();
    await database.close();
  }
}
