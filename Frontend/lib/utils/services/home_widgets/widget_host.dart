import 'dart:developer';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Names shared with the native widgets. Keep them in sync with
/// android/app/src/main/kotlin/com/invospec/daymark/widgets/ and
/// ios/DaymarkWidgets/.
class DaymarkWidgets {
  /// iOS App Group shared by the Runner and the DaymarkWidgets extension.
  static const appGroupId = 'group.com.devquorix.daymark';

  static const tasksAndroid = 'com.invospec.daymark.widgets.TasksWidgetReceiver';
  static const reminderAndroid = 'com.invospec.daymark.widgets.NextReminderWidgetReceiver';

  /// WidgetKit kinds.
  static const tasksIOS = 'DaymarkTasksWidget';
  static const reminderIOS = 'DaymarkNextReminderWidget';

  /// iOS: widget button taps the app still has to apply (a JSON list of
  /// `daymark://widget/...` links, written by DaymarkWidgetIntent).
  static const pendingActionsKey = 'daymark_widget_pending_actions';

  /// iOS: taps the widgets show at once until the app confirms them.
  static const optimisticKeys = [
    'daymark_widget_optimistic_done',
    'daymark_widget_answered_reminders',
  ];
}

/// The home_widget calls the app makes, behind an interface so tests can
/// fake them. On web and desktop [isSupported] is false and every call is a
/// no-op.
abstract class WidgetHost {
  bool get isSupported;

  Future<void> saveString(String key, String? value);

  Future<String?> readString(String key);

  /// Redraws both widgets from the saved data.
  Future<void> updateAll();

  /// Android: redraws the Next reminder widget at each of [times] even if the
  /// app isn't running (AlarmManager via home_widget; survives reboots).
  /// iOS uses timeline entries instead, so this does nothing there.
  Future<void> scheduleReminderRefreshes(List<DateTime> times);
}

/// The real home_widget plugin.
class HomeWidgetHost implements WidgetHost {
  bool _groupSet = false;

  @override
  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _ensureGroup() async {
    if (_groupSet || !Platform.isIOS) return;
    await HomeWidget.setAppGroupId(DaymarkWidgets.appGroupId);
    _groupSet = true;
  }

  @override
  Future<void> saveString(String key, String? value) async {
    if (!isSupported) return;
    await _ensureGroup();
    await HomeWidget.saveWidgetData<String>(key, value);
  }

  @override
  Future<String?> readString(String key) async {
    if (!isSupported) return null;
    await _ensureGroup();
    return HomeWidget.getWidgetData<String>(key);
  }

  @override
  Future<void> updateAll() async {
    if (!isSupported) return;
    await _ensureGroup();
    for (final (android, ios) in const [
      (DaymarkWidgets.tasksAndroid, DaymarkWidgets.tasksIOS),
      (DaymarkWidgets.reminderAndroid, DaymarkWidgets.reminderIOS),
    ]) {
      try {
        await HomeWidget.updateWidget(qualifiedAndroidName: android, iOSName: ios);
      } catch (error) {
        // A build without that widget (or none placed yet on some launchers).
        log('Could not update the widget $android / $ios: $error');
      }
    }
  }

  @override
  Future<void> scheduleReminderRefreshes(List<DateTime> times) async {
    if (!isSupported || !Platform.isAndroid) return;
    try {
      if (times.isEmpty) {
        await HomeWidget.cancelScheduledWidgetUpdates(
          qualifiedAndroidName: DaymarkWidgets.reminderAndroid,
        );
      } else {
        await HomeWidget.scheduleWidgetUpdates(
          times,
          qualifiedAndroidName: DaymarkWidgets.reminderAndroid,
        );
      }
    } catch (error) {
      log('Could not schedule the reminder widget refresh: $error');
    }
  }
}
