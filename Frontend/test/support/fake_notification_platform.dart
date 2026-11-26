import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// One notification the fake OS has scheduled.
class FakeScheduled {
  final int id;
  final tz.TZDateTime at;
  final String title;
  final String body;
  final String? payload;
  final NotificationDetails details;
  final AndroidScheduleMode mode;
  final DateTimeComponents? matching;

  FakeScheduled({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
    required this.details,
    required this.mode,
    required this.matching,
  });
}

/// An in-memory OS for [NotificationService] tests: records what was
/// scheduled, shown and cancelled, and answers permission checks from fields.
class FakeNotificationPlatform implements NotificationPlatform {
  final Map<int, FakeScheduled> scheduled = {};
  final List<FakeScheduled> shown = [];
  final List<int> cancelled = [];
  final List<AndroidNotificationChannel> channels = [];
  final List<String> calls = [];
  int scheduleCalls = 0;

  InitializationSettings? settings;
  DidReceiveNotificationResponseCallback? onForeground;
  DidReceiveBackgroundNotificationResponseCallback? onBackground;
  NotificationAppLaunchDetails? launch;

  bool enabled = true;
  bool exact = true;

  /// What the OS prompt answers; null keeps [enabled] as it is.
  bool? grantOnRequest;
  int permissionRequests = 0;
  int exactRequests = 0;
  int settingsOpened = 0;

  String timezone = 'UTC';
  bool timezoneFails = false;

  @override
  Future<void> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onForegroundResponse,
    DidReceiveBackgroundNotificationResponseCallback? onBackgroundResponse,
  }) async {
    calls.add('initialize');
    this.settings = settings;
    onForeground = onForegroundResponse;
    onBackground = onBackgroundResponse;
  }

  @override
  Future<void> createAndroidChannel(AndroidNotificationChannel channel) async {
    channels.add(channel);
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
  }) async {
    scheduleCalls++;
    calls.add('schedule $id');
    scheduled[id] = FakeScheduled(
      id: id,
      at: scheduledDate,
      title: title,
      body: body,
      payload: payload,
      details: details,
      mode: androidScheduleMode,
      matching: matchDateTimeComponents,
    );
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
    String? payload,
  }) async {
    calls.add('show $id');
    shown.add(FakeScheduled(
      id: id,
      at: tz.TZDateTime.now(tz.UTC),
      title: title,
      body: body,
      payload: payload,
      details: details,
      mode: AndroidScheduleMode.exact,
      matching: null,
    ));
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel $id');
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
    scheduled.clear();
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async => [
    for (final s in scheduled.values) PendingNotificationRequest(s.id, s.title, s.body, s.payload),
  ];

  @override
  Future<NotificationAppLaunchDetails?> launchDetails() async => launch;

  @override
  Future<bool?> areNotificationsEnabled() async => enabled;

  @override
  Future<bool?> requestNotificationsPermission() async {
    permissionRequests++;
    if (grantOnRequest != null) enabled = grantOnRequest!;
    return enabled;
  }

  @override
  Future<bool?> canScheduleExactNotifications() async => exact;

  @override
  Future<bool?> requestExactAlarmsPermission() async {
    exactRequests++;
    return exact;
  }

  @override
  Future<bool?> openAppNotificationSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<String> localTimezone() async {
    if (timezoneFails) throw StateError('no time zone');
    return timezone;
  }
}
