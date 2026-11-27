import 'dart:async';
import 'dart:developer';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notes_app/utils/services/background_graph.dart';
import 'package:notes_app/utils/services/home_widgets/widget_background.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';

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
    final graph = await BackgroundGraph.open();
    try {
      final result = await graph.reminderActions.handle(response.actionId, response.payload);
      log('Background reminder action ${response.actionId}: ${result.outcome.name}');
      // W-01: answering from the notification updates the home-screen widgets.
      if (result.outcome == ReminderActionOutcome.answered ||
          result.outcome == ReminderActionOutcome.snoozed) {
        await updateWidgetsFromBackground(
          database: graph.database,
          userId: graph.userId,
          timezoneReady: true,
        );
      }
    } finally {
      await graph.close();
    }
  } catch (error, stackTrace) {
    // A crash here would lose the tap silently: always log it.
    log('Background reminder action failed: $error', stackTrace: stackTrace);
  }
}
