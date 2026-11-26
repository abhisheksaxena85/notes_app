import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/utils/services/digest_scheduler.dart';
import 'package:notes_app/utils/services/local_reminder_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_notification_platform.dart';

/// REM-08: the daily reminder and weekly summary settings schedule real
/// notifications.
void main() {
  const userId = 42;
  late tz.Location berlin;
  late AppDatabase database;
  late FakeNotificationPlatform platform;
  late DigestScheduler digests;
  late tz.TZDateTime now;
  var signedIn = userId;

  setUpAll(() {
    tzdata.initializeTimeZones();
    berlin = tz.getLocation('Europe/Berlin');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Preference.init();
    tz.setLocalLocation(berlin);
    // Thursday.
    now = tz.TZDateTime(berlin, 2026, 11, 26, 9);
    signedIn = userId;
    database = AppDatabase.forTesting(NativeDatabase.memory());
    platform = FakeNotificationPlatform();
    digests = DigestScheduler(
      notifications: NotificationService(platform: platform, supported: true, android: true),
      preference: Preference(),
      database: database,
      currentUserId: () => signedIn,
      now: () => now,
    );
  });

  tearDown(() => database.close());

  group('daily reminder', () {
    test('scheduled every day at the chosen time, without actions', () async {
      await digests.setDaily(true, time: const TimeOfDay(hour: 9, minute: 2));

      final daily = platform.scheduled[DigestScheduler.dailyId]!;
      expect(daily.at, tz.TZDateTime(berlin, 2026, 11, 26, 9, 2), reason: '2 minutes ahead: today');
      expect(daily.matching, DateTimeComponents.time);
      expect(daily.title, 'Plan your day');
      expect(daily.body, "Open Daymark to review today's tasks and reminders.");
      expect(daily.details.android!.channelId, 'digests');
      expect(daily.details.android!.actions, isNull);
      expect(digestKindOf(daily.payload), 'daily');
      expect(digests.dailyEnabled, isTrue);
      expect(Preference().getString(LocalReminderService.keyDailyReminderTime), '09:02');
    });

    test('a time already passed today starts tomorrow', () async {
      await digests.setDaily(true, time: const TimeOfDay(hour: 8, minute: 30));
      expect(platform.scheduled[DigestScheduler.dailyId]!.at, tz.TZDateTime(berlin, 2026, 11, 27, 8, 30));
    });

    test('changing the time reschedules it; turning it off cancels it', () async {
      await digests.setDaily(true, time: const TimeOfDay(hour: 20, minute: 0));
      await digests.setDaily(true, time: const TimeOfDay(hour: 21, minute: 15));
      expect(platform.scheduled[DigestScheduler.dailyId]!.at, tz.TZDateTime(berlin, 2026, 11, 26, 21, 15));

      await digests.setDaily(false);
      expect(platform.scheduled.containsKey(DigestScheduler.dailyId), isFalse);
      expect(digests.dailyEnabled, isFalse);
    });
  });

  group('weekly summary', () {
    test('scheduled for the next Sunday 18:00 local', () async {
      await digests.setWeekly(true);
      final weekly = platform.scheduled[DigestScheduler.weeklyId]!;
      expect(weekly.at, tz.TZDateTime(berlin, 2026, 11, 29, 18));
      expect(weekly.matching, DateTimeComponents.dayOfWeekAndTime);
      expect(digestKindOf(weekly.payload), 'weekly');
    });

    test('on Sunday after 18:00 it is next week', () {
      now = tz.TZDateTime(berlin, 2026, 11, 29, 18, 30);
      expect(digests.nextWeeklyTime(), tz.TZDateTime(berlin, 2026, 12, 6, 18));
      now = tz.TZDateTime(berlin, 2026, 11, 29, 17, 59);
      expect(digests.nextWeeklyTime(), tz.TZDateTime(berlin, 2026, 11, 29, 18));
    });

    test('the body counts this week\'s done tasks and missed reminders', () async {
      Future<void> task(String status, String updatedAt) => database.into(database.cachedTasks).insert(
        CachedTasksCompanion.insert(
          userId: userId,
          title: 't',
          status: Value(status),
          updatedAt: Value(updatedAt),
        ),
      );
      Future<void> reminder(String remindAt, {String status = 'PENDING', String interval = 'NONE',
          String? lastOutcome, String? lastOutcomeAt}) =>
          database.into(database.cachedReminders).insert(CachedRemindersCompanion.insert(
            userId: userId,
            title: 'r',
            remindAt: remindAt,
            status: Value(status),
            repeatInterval: Value(interval),
            lastOutcome: Value(lastOutcome),
            lastOutcomeAt: Value(lastOutcomeAt),
          ));

      await task('COMPLETED', '2026-11-25T10:00:00.000Z');
      await task('COMPLETED', '2026-11-20T10:00:00.000Z');
      await task('COMPLETED', '2026-11-01T10:00:00.000Z'); // older than a week
      await task('PENDING', '2026-11-25T10:00:00.000Z');
      await reminder('2026-11-24T08:00:00'); // passed, unanswered
      await reminder('2026-11-23T08:00:00', status: 'MISSED');
      await reminder('2026-11-22T08:00:00', status: 'COMPLETED');
      await reminder('2026-11-27T08:00:00'); // still to come
      await reminder('2026-11-10T08:00:00', status: 'MISSED'); // older
      await reminder('2026-11-27T08:00:00', interval: 'DAILY', lastOutcome: 'MISSED',
          lastOutcomeAt: '2026-11-26T08:00:00');

      expect(await digests.weeklySummaryText(), 'This week: 2 tasks done, 3 reminders missed');

      signedIn = 0;
      expect(await digests.weeklySummaryText(), 'Open Daymark to see how your week went.');
    });
  });

  group('reconcile on app open', () {
    test('schedules digests that are on but missing (reinstall, cleared data)', () async {
      await LocalReminderService.save(Preference(), daily: true, dailyTime: const TimeOfDay(hour: 7, minute: 0), weekly: true);
      await digests.reconcile();
      expect(platform.scheduled.keys, unorderedEquals([DigestScheduler.dailyId, DigestScheduler.weeklyId]));
    });

    test('refreshes the weekly counts and drops digests that are off', () async {
      await digests.setWeekly(true);
      await digests.setDaily(true, time: const TimeOfDay(hour: 7, minute: 0));
      final calls = platform.scheduleCalls;
      await LocalReminderService.save(Preference(), daily: false);
      await digests.reconcile();
      expect(platform.scheduleCalls, calls + 1, reason: 'weekly rescheduled with fresh counts');
      expect(platform.scheduled.keys, [DigestScheduler.weeklyId]);
    });

    test('does nothing on unsupported platforms', () async {
      await LocalReminderService.save(Preference(), daily: true, weekly: true);
      final off = DigestScheduler(
        notifications: NotificationService(platform: platform, supported: false),
        preference: Preference(),
        database: database,
        currentUserId: () => userId,
        now: () => now,
      );
      await off.reconcile();
      expect(platform.calls, isEmpty);
    });
  });

  test('digestKindOf ignores reminders and garbage', () {
    expect(digestKindOf('{"type":"digest","kind":"weekly"}'), 'weekly');
    expect(digestKindOf('{"v":1,"type":"reminder"}'), isNull);
    expect(digestKindOf('nope'), isNull);
    expect(digestKindOf(null), isNull);
  });
}
