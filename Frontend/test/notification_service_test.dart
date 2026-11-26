import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_notification_platform.dart';

/// REM-01: NotificationService builds the right notifications and stays a
/// no-op where notifications aren't supported.
void main() {
  late FakeNotificationPlatform platform;
  late NotificationService service;

  setUp(() {
    platform = FakeNotificationPlatform()..timezone = 'Europe/Berlin';
    service = NotificationService(platform: platform, supported: true, android: true);
  });

  test('init sets the device time zone, channels and callbacks', () async {
    await service.init(
      onForegroundResponse: (_) {},
      onBackgroundResponse: notificationTapBackground,
    );

    expect(tz.local.name, 'Europe/Berlin');
    expect(service.timezone, 'Europe/Berlin');
    expect(platform.channels.map((c) => c.id), ['reminders', 'digests']);
    expect(platform.channels.first.importance, Importance.high);
    expect(platform.onBackground, notificationTapBackground);

    final darwin = platform.settings!.iOS!;
    expect(darwin.requestAlertPermission, isFalse, reason: 'REM-02 asks later');
    final category = darwin.notificationCategories.single;
    expect(category.identifier, 'daymark_reminder');
    expect(category.actions.map((a) => a.identifier),
        ['reminder_done', 'reminder_not_done', 'reminder_snooze']);
    expect(platform.settings!.android!.defaultIcon, 'ic_stat_daymark');
  });

  test('an unknown device zone falls back to UTC', () async {
    platform.timezoneFails = true;
    await service.init(onForegroundResponse: (_) {});
    expect(tz.local, tz.UTC);
  });

  test('refreshTimezone reports a change', () async {
    await service.init(onForegroundResponse: (_) {});
    expect(await service.refreshTimezone(), isFalse);
    platform.timezone = 'America/New_York';
    expect(await service.refreshTimezone(), isTrue);
    expect(tz.local.name, 'America/New_York');
  });

  test('reminder notifications carry three background actions', () {
    final details = NotificationService.notificationDetails(
      channel: NotificationChannels.reminders,
      withActions: true,
      when: DateTime.utc(2026, 11, 26, 18),
    );
    final android = details.android!;
    expect(android.channelId, 'reminders');
    expect(android.icon, 'ic_stat_daymark');
    expect(android.category, AndroidNotificationCategory.reminder);
    expect(android.importance, Importance.high);
    expect(android.when, DateTime.utc(2026, 11, 26, 18).millisecondsSinceEpoch);
    expect(android.actions!.map((a) => (a.id, a.title)), [
      ('reminder_done', 'Done'),
      ('reminder_not_done', 'Not done'),
      ('reminder_snooze', 'Snooze 10 min'),
    ]);
    for (final action in android.actions!) {
      expect(action.showsUserInterface, isFalse);
      expect(action.cancelNotification, isTrue);
    }
    expect(details.iOS!.categoryIdentifier, 'daymark_reminder');
    expect(details.iOS!.presentBanner, isTrue);
    expect(details.iOS!.interruptionLevel, InterruptionLevel.active);
  });

  test('digest notifications have no actions', () {
    final details = NotificationService.notificationDetails(
      channel: NotificationChannels.digests,
      withActions: false,
    );
    expect(details.android!.actions, isNull);
    expect(details.android!.channelId, 'digests');
    expect(details.iOS!.categoryIdentifier, isNull);
  });

  test('schedule uses exact alarms only when they are allowed', () async {
    await service.init(onForegroundResponse: (_) {});
    final at = tz.TZDateTime(tz.local, 2030, 1, 1, 9);

    await service.schedule(id: 1, at: at, title: 'T', body: 'B', payload: '{}');
    expect(platform.scheduled[1]!.mode, AndroidScheduleMode.exactAllowWhileIdle);
    expect(platform.scheduled[1]!.at, at);

    platform.exact = false;
    await service.schedule(id: 2, at: at, title: 'T', body: 'B', payload: '{}');
    expect(platform.scheduled[2]!.mode, AndroidScheduleMode.inexactAllowWhileIdle);
  });

  test('unsupported platforms (web, Windows, Linux) are a no-op', () async {
    final off = NotificationService(platform: platform, supported: false);
    await off.init(onForegroundResponse: (_) {});
    await off.schedule(
      id: 1,
      at: tz.TZDateTime.now(tz.UTC),
      title: 'T',
      body: 'B',
      payload: '{}',
    );
    await off.showNow(id: 2, title: 'T', body: 'B');
    await off.cancel(1);
    await off.cancelAll();

    expect(off.isSupported, isFalse);
    expect(await off.pending(), isEmpty);
    expect(await off.areEnabled(), isFalse);
    expect(await off.requestPermission(), isFalse);
    expect(await off.launchDetails(), isNull);
    expect(platform.calls, isEmpty);
  });
}
