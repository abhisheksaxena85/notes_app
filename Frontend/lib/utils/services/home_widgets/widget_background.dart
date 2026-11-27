import 'dart:developer';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/utils/services/home_widgets/widget_host.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// W-01: refreshes the home-screen widgets from a background isolate (the
/// REM-04 notification action handler, the W-02 widget actions), where
/// get_it and the app's services don't exist.
///
/// Pass the isolate's open [database] and the [userId] it acts for when it
/// has them; otherwise both are read here (and the database closed after).
/// [timezoneReady] skips loading the time zone database when the caller
/// already did. Never throws.
Future<void> updateWidgetsFromBackground({
  AppDatabase? database,
  int? userId,
  bool timezoneReady = false,
}) async {
  final host = HomeWidgetHost();
  if (!host.isSupported) return;
  AppDatabase? opened;
  try {
    var user = userId;
    if (user == null) {
      // The main isolate may have changed the session since this isolate
      // last read the preferences (they are cached per isolate).
      await Preference.init();
      await Preference.pref.reload();
      user = SessionService.storedUserId(Preference());
    }
    if (!timezoneReady) await NotificationService().initTimezone();
    var db = database;
    if (db == null) {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = opened = AppDatabase();
    }
    final service = WidgetSnapshotService(
      database: db,
      host: host,
      currentUserId: () => user!,
      now: () => tz.TZDateTime.now(tz.local),
    );
    await service.refresh();
  } catch (error, stackTrace) {
    log('Background widget refresh failed: $error', stackTrace: stackTrace);
  } finally {
    await opened?.close();
  }
}
