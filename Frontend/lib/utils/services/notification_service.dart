import 'dart:developer';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Action ids of the buttons on a reminder notification (REM-04).
class ReminderActions {
  static const done = 'reminder_done';
  static const notDone = 'reminder_not_done';
  static const snooze = 'reminder_snooze';

  /// iOS/macOS category that carries the three buttons.
  static const darwinCategory = 'daymark_reminder';
}

/// Android notification channels.
class NotificationChannels {
  static const reminders = 'reminders';
  static const digests = 'digests';
}

/// The plugin calls [NotificationService] makes, so tests can replace the OS
/// with a fake. [PluginNotificationPlatform] is the real one.
abstract class NotificationPlatform {
  Future<void> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onForegroundResponse,
    DidReceiveBackgroundNotificationResponseCallback? onBackgroundResponse,
  });

  /// Android only; a no-op elsewhere.
  Future<void> createAndroidChannel(AndroidNotificationChannel channel);

  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
    required String title,
    required String body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  });

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
    String? payload,
  });

  Future<void> cancel(int id);
  Future<void> cancelAll();
  Future<List<PendingNotificationRequest>> pendingNotificationRequests();
  Future<NotificationAppLaunchDetails?> launchDetails();

  /// Whether the OS lets the app post notifications (null if unknown).
  Future<bool?> areNotificationsEnabled();

  /// Shows the OS permission prompt (Android 13+, iOS, macOS).
  Future<bool?> requestNotificationsPermission();

  /// Android 12+: whether exact alarms are allowed. True elsewhere.
  Future<bool?> canScheduleExactNotifications();

  /// Android 12+: opens the "Alarms & reminders" setting.
  Future<bool?> requestExactAlarmsPermission();

  Future<bool?> openAppNotificationSettings();

  /// The device's IANA time zone, e.g. `Europe/Berlin`.
  Future<String> localTimezone();
}

/// [NotificationPlatform] backed by flutter_local_notifications.
class PluginNotificationPlatform implements NotificationPlatform {
  final FlutterLocalNotificationsPlugin _plugin;

  PluginNotificationPlatform([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  MacOSFlutterLocalNotificationsPlugin? get _macos => _plugin
      .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();

  @override
  Future<void> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onForegroundResponse,
    DidReceiveBackgroundNotificationResponseCallback? onBackgroundResponse,
  }) async {
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
    );
  }

  @override
  Future<void> createAndroidChannel(AndroidNotificationChannel channel) async {
    await _android?.createNotificationChannel(channel);
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
    required String title,
    required String body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) => _plugin.zonedSchedule(
    id: id,
    scheduledDate: scheduledDate,
    notificationDetails: details,
    androidScheduleMode: androidScheduleMode,
    title: title,
    body: body,
    payload: payload,
    matchDateTimeComponents: matchDateTimeComponents,
  );

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
    String? payload,
  }) => _plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: details,
    payload: payload,
  );

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() =>
      _plugin.pendingNotificationRequests();

  @override
  Future<NotificationAppLaunchDetails?> launchDetails() =>
      _plugin.getNotificationAppLaunchDetails();

  @override
  Future<bool?> areNotificationsEnabled() async {
    if (_android case final android?) return android.areNotificationsEnabled();
    if (_ios case final ios?) return (await ios.checkPermissions())?.isEnabled;
    if (_macos case final macos?) return (await macos.checkPermissions())?.isEnabled;
    return null;
  }

  @override
  Future<bool?> requestNotificationsPermission() async {
    if (_android case final android?) return android.requestNotificationsPermission();
    if (_ios case final ios?) {
      return ios.requestPermissions(alert: true, badge: true, sound: true);
    }
    if (_macos case final macos?) {
      return macos.requestPermissions(alert: true, badge: true, sound: true);
    }
    return null;
  }

  @override
  Future<bool?> canScheduleExactNotifications() async =>
      _android == null ? true : _android!.canScheduleExactNotifications();

  @override
  Future<bool?> requestExactAlarmsPermission() async =>
      _android == null ? true : _android!.requestExactAlarmsPermission();

  @override
  Future<bool?> openAppNotificationSettings() => _plugin.openAppNotificationSettings();

  @override
  Future<String> localTimezone() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;
}

/// REM-01: the app's only access to OS notifications (registered in get_it).
///
/// Android, iOS and macOS only. Everywhere else (web, Windows, Linux)
/// [isSupported] is false and every call is a no-op, so callers don't need
/// platform checks.
class NotificationService {
  final NotificationPlatform _platform;
  final bool isSupported;
  final bool _isAndroid;

  bool _initialized = false;
  String? _timezone;

  NotificationService({
    NotificationPlatform? platform,
    bool? supported,
    bool? android,
  }) : _platform = platform ?? PluginNotificationPlatform(),
       isSupported = supported ?? _platformSupported(),
       _isAndroid = android ?? (!kIsWeb && Platform.isAndroid);

  static bool _platformSupported() =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  bool get isInitialized => _initialized;

  /// The IANA zone reminders are scheduled in (null before [init]).
  String? get timezone => _timezone;

  /// Loads the time zone database, sets the device zone as `tz.local`,
  /// creates the Android channels and registers the tap/action callbacks.
  ///
  /// [onBackgroundResponse] must be a top-level function annotated with
  /// `@pragma('vm:entry-point')` (see `notificationTapBackground`).
  Future<void> init({
    required DidReceiveNotificationResponseCallback onForegroundResponse,
    DidReceiveBackgroundNotificationResponseCallback? onBackgroundResponse,
  }) async {
    if (!isSupported || _initialized) return;
    await initTimezone();

    final darwin = DarwinInitializationSettings(
      // REM-02 asks at the right moment instead of at launch.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          ReminderActions.darwinCategory,
          actions: [
            DarwinNotificationAction.plain(ReminderActions.done, 'Done'),
            DarwinNotificationAction.plain(
              ReminderActions.notDone,
              'Not done',
              options: {DarwinNotificationActionOption.destructive},
            ),
            DarwinNotificationAction.plain(ReminderActions.snooze, 'Snooze 10 min'),
          ],
        ),
      ],
    );
    await _platform.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('ic_stat_daymark'),
        iOS: darwin,
        macOS: darwin,
      ),
      onForegroundResponse: onForegroundResponse,
      onBackgroundResponse: onBackgroundResponse,
    );
    if (_isAndroid) {
      await _platform.createAndroidChannel(
        const AndroidNotificationChannel(
          NotificationChannels.reminders,
          'Reminders',
          description: 'Alerts when a reminder is due',
          importance: Importance.high,
        ),
      );
      await _platform.createAndroidChannel(
        const AndroidNotificationChannel(
          NotificationChannels.digests,
          'Daily & weekly summaries',
          description: 'The daily planning reminder and the weekly summary',
        ),
      );
    }
    _initialized = true;
  }

  /// Loads the time zone database and points `tz.local` at the device zone.
  /// Falls back to UTC if the zone can't be read or isn't known. Safe to call
  /// again (background isolate, app resume).
  Future<void> initTimezone() async {
    tzdata.initializeTimeZones();
    await refreshTimezone();
  }

  /// Re-reads the device zone; returns true if it changed (the user
  /// travelled or changed the setting), so reminders must be rescheduled.
  Future<bool> refreshTimezone() async {
    String name;
    try {
      name = await _platform.localTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (error) {
      log('Could not read the device time zone, using UTC: $error');
      name = 'UTC';
      tz.setLocalLocation(tz.UTC);
    }
    final changed = _timezone != null && _timezone != name;
    _timezone = name;
    return changed;
  }

  /// How the app was launched, for a cold start from a notification tap.
  Future<NotificationAppLaunchDetails?> launchDetails() async =>
      isSupported ? _platform.launchDetails() : null;

  /// Schedules a notification at [at] (wall clock in `tz.local`). Replaces
  /// any pending notification with the same [id].
  Future<void> schedule({
    required int id,
    required tz.TZDateTime at,
    required String title,
    required String body,
    required String payload,
    String channel = NotificationChannels.reminders,
    bool withActions = true,
    DateTimeComponents? repeatMatching,
  }) async {
    if (!isSupported) return;
    await _platform.zonedSchedule(
      id: id,
      scheduledDate: at,
      details: notificationDetails(channel: channel, withActions: withActions, when: at),
      androidScheduleMode: await scheduleMode(),
      title: title,
      body: body,
      payload: payload,
      matchDateTimeComponents: repeatMatching,
    );
  }

  /// Exact when the user allowed exact alarms (Android 12+), otherwise
  /// inexact: the OS may deliver it a few minutes late.
  Future<AndroidScheduleMode> scheduleMode() async =>
      await canScheduleExact()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

  /// Shows a notification now (the debug "Test notification" button).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channel = NotificationChannels.reminders,
    bool withActions = true,
  }) async {
    if (!isSupported) return;
    await _platform.show(
      id: id,
      title: title,
      body: body,
      details: notificationDetails(channel: channel, withActions: withActions),
      payload: payload,
    );
  }

  Future<void> cancel(int id) async {
    if (isSupported) await _platform.cancel(id);
  }

  Future<void> cancelAll() async {
    if (isSupported) await _platform.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pending() async =>
      isSupported ? _platform.pendingNotificationRequests() : const [];

  // ---------------------------------------------------------------------------
  // Permissions (REM-02)
  // ---------------------------------------------------------------------------

  /// Whether the OS currently lets the app post notifications.
  Future<bool> areEnabled() async =>
      isSupported && (await _platform.areNotificationsEnabled() ?? false);

  /// Shows the OS prompt; true if notifications are allowed afterwards.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    final granted = await _platform.requestNotificationsPermission();
    return granted ?? await areEnabled();
  }

  /// Android 12+: exact alarms allowed. Always true on other platforms.
  Future<bool> canScheduleExact() async {
    if (!isSupported) return false;
    if (!_isAndroid) return true;
    return await _platform.canScheduleExactNotifications() ?? false;
  }

  /// Android 12+: opens the system screen to allow exact alarms. The result
  /// is only known after the user comes back (re-check on resume).
  Future<void> requestExact() async {
    if (isSupported && _isAndroid) await _platform.requestExactAlarmsPermission();
  }

  /// Opens the app's notification settings page in the OS.
  Future<void> openSettings() async {
    if (isSupported) await _platform.openAppNotificationSettings();
  }

  /// The platform details of a Daymark notification. Reminders get the
  /// Done / Not done / Snooze buttons; digests don't.
  @visibleForTesting
  static NotificationDetails notificationDetails({
    required String channel,
    required bool withActions,
    DateTime? when,
  }) {
    final isReminder = channel == NotificationChannels.reminders;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        isReminder ? 'Reminders' : 'Daily & weekly summaries',
        importance: isReminder ? Importance.high : Importance.defaultImportance,
        priority: isReminder ? Priority.high : Priority.defaultPriority,
        category: isReminder ? AndroidNotificationCategory.reminder : null,
        icon: 'ic_stat_daymark',
        when: when?.millisecondsSinceEpoch,
        showWhen: true,
        actions: withActions
            ? const [
                // showsUserInterface: false runs the answer in the background
                // without opening the app (REM-04).
                AndroidNotificationAction(
                  ReminderActions.done,
                  'Done',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
                AndroidNotificationAction(
                  ReminderActions.notDone,
                  'Not done',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
                AndroidNotificationAction(
                  ReminderActions.snooze,
                  'Snooze 10 min',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
              ]
            : null,
      ),
      iOS: _darwin(withActions),
      macOS: _darwin(withActions),
    );
  }

  static DarwinNotificationDetails _darwin(bool withActions) => DarwinNotificationDetails(
    categoryIdentifier: withActions ? ReminderActions.darwinCategory : null,
    // `timeSensitive` would need the Time Sensitive Notifications entitlement.
    interruptionLevel: InterruptionLevel.active,
    // Show it even while the app is open.
    presentAlert: true,
    presentBanner: true,
    presentList: true,
    presentSound: true,
  );
}

/// Runs when the user taps a notification action while the app isn't
/// running (or on Android, for every action that doesn't open the app). It
/// runs in a separate background isolate. REM-04 handles the answer here.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  log('Notification action ${response.actionId} received in the background');
}
