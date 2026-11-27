import 'dart:async';
import 'dart:developer';
import 'dart:ui' show DartPluginRegistrant;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/secure_storage/token_store.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';
import 'package:notes_app/utils/services/reminder_scheduler.dart';

/// Actions arriving while one is handled wait for it (the plugin reuses one
/// background isolate and doesn't wait for the callback).
Future<void> _queue = Future.value();

/// REM-04: Done / Not done / Snooze tapped while the app is killed or in the
/// background (on Android: every one of these actions, even with the app
/// open). Runs in a separate background isolate started by the plugin.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  _queue = _queue.then((_) => _handleInBackground(response));
}

Future<void> _handleInBackground(NotificationResponse response) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final graph = await _BackgroundGraph.open();
    try {
      final result = await graph.handler.handle(response.actionId, response.payload);
      log('Background reminder action ${response.actionId}: ${result.outcome.name}');
    } finally {
      await graph.close();
    }
  } catch (error, stackTrace) {
    // A crash here would lose the tap silently: always log it.
    log('Background reminder action failed: $error', stackTrace: stackTrace);
  }
}

/// The minimum the action handler needs: no connectivity listener, no sync
/// loop or retry timers, no Riverpod. Built per action and closed after.
class _BackgroundGraph {
  final AppDatabase database;
  final OfflineSyncService sync;
  final ReminderActionHandler handler;

  _BackgroundGraph(this.database, this.sync, this.handler);

  static Future<_BackgroundGraph> open() async {
    // The main isolate may have changed the session since this isolate
    // last read the preferences (they are cached per isolate).
    await Preference.init();
    await Preference.pref.reload();
    final userId = SessionService.storedUserId(Preference());

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final database = AppDatabase();
    // SEC-02: its own Dio with the auth interceptor, reading the token the
    // app saved (a fresh TokenStore, so nothing cached from an older
    // session). A 401 here only fails the upload: the change stays queued
    // and the app signs the user out on its next request.
    final client = ApiClient(dioClient: DioClient.create(tokenStore: TokenStore.platform()));
    // No connectivity service: nothing listens or retries in this isolate.
    final sync = OfflineSyncService(client: client, database: database);
    final repo = ReminderRepo(client: client, database: database, syncService: sync);

    // The plugin must be initialised in this isolate before scheduling; the
    // same callbacks keep the registration as the app made it.
    final notifications = NotificationService();
    await notifications.init(
      onForegroundResponse: (_) {},
      onBackgroundResponse: notificationTapBackground,
    );
    final scheduler = ReminderScheduler(
      database: database,
      repo: repo,
      notifications: notifications,
      currentUserId: () => userId,
    );
    final handler = ReminderActionHandler(
      database: database,
      repo: repo,
      scheduler: scheduler,
      currentUserId: () => userId,
      pushChanges: () {
        sync.setUserId(userId);
        return sync.requestSync();
      },
    );
    return _BackgroundGraph(database, sync, handler);
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
