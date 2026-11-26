import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/network/dto/response/item_status.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/local/database/reminder_database_mapper.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:notes_app/utils/services/local_reminder_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Which digest a notification is ("daily" or "weekly"), from its payload.
/// Null for anything else.
String? digestKindOf(String? payload) {
  if (payload == null) return null;
  try {
    final json = jsonDecode(payload);
    if (json is Map && json['type'] == DigestScheduler.payloadType) {
      return json['kind']?.toString();
    }
  } on FormatException {
    // Not a digest.
  }
  return null;
}

/// REM-08: the "Daily reminder" and "Weekly summary" settings.
///
/// The on/off state and the daily time stay in SharedPreferences
/// ([LocalReminderService] keys); this schedules the matching repeating
/// notifications on the `digests` channel, without action buttons:
/// - daily: id [dailyId], every day at the chosen time;
/// - weekly: id [weeklyId], Sundays 18:00 local, with this week's counts.
class DigestScheduler {
  static const dailyId = 900001;
  static const weeklyId = 900002;
  static const payloadType = 'digest';
  static const weeklyHour = 18;

  final NotificationService notifications;
  final Preference preference;
  final AppDatabase database;
  final int Function() currentUserId;
  final tz.TZDateTime Function() _now;

  DigestScheduler({
    required this.notifications,
    required this.preference,
    required this.database,
    required this.currentUserId,
    tz.TZDateTime Function()? now,
  }) : _now = now ?? (() => tz.TZDateTime.now(tz.local));

  bool get dailyEnabled => preference.getBool(LocalReminderService.keyDailyReminder) ?? false;
  bool get weeklyEnabled => preference.getBool(LocalReminderService.keyWeeklySummary) ?? false;

  TimeOfDay get dailyTime {
    final parts = (preference.getString(LocalReminderService.keyDailyReminderTime) ?? '').split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return TimeOfDay(hour: hour ?? 9, minute: minute ?? 0);
  }

  /// Turns the daily reminder on (at [time], or the saved time) or off.
  Future<void> setDaily(bool enabled, {TimeOfDay? time}) async {
    await LocalReminderService.save(preference, daily: enabled, dailyTime: time);
    if (enabled) {
      await _scheduleDaily();
    } else {
      await notifications.cancel(dailyId);
    }
  }

  Future<void> setWeekly(bool enabled) async {
    await LocalReminderService.save(preference, weekly: enabled);
    if (enabled) {
      await _scheduleWeekly();
    } else {
      await notifications.cancel(weeklyId);
    }
  }

  /// App start and resume: schedules digests that are on but missing (a
  /// reinstall or cleared data), and refreshes the weekly counts.
  Future<void> reconcile() async {
    if (!notifications.isSupported) return;
    try {
      final pending = {for (final p in await notifications.pending()) p.id};
      if (dailyEnabled && !pending.contains(dailyId)) await _scheduleDaily();
      if (!dailyEnabled && pending.contains(dailyId)) await notifications.cancel(dailyId);
      if (weeklyEnabled) {
        await _scheduleWeekly();
      } else if (pending.contains(weeklyId)) {
        await notifications.cancel(weeklyId);
      }
    } catch (error, stackTrace) {
      log('Digest reconcile failed: $error', stackTrace: stackTrace);
    }
  }

  Future<void> _scheduleDaily() async {
    final time = dailyTime;
    final now = _now();
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!at.isAfter(now)) {
      at = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, time.hour, time.minute);
    }
    await notifications.schedule(
      id: dailyId,
      at: at,
      title: 'Plan your day',
      body: "Open Daymark to review today's tasks and reminders.",
      payload: jsonEncode({'type': payloadType, 'kind': 'daily'}),
      channel: NotificationChannels.digests,
      withActions: false,
      repeatMatching: DateTimeComponents.time,
    );
  }

  /// The next Sunday 18:00 local time strictly after now.
  tz.TZDateTime nextWeeklyTime() {
    final now = _now();
    final ahead = (DateTime.sunday - now.weekday) % 7;
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day + ahead, weeklyHour);
    if (!at.isAfter(now)) {
      at = tz.TZDateTime(tz.local, now.year, now.month, now.day + ahead + 7, weeklyHour);
    }
    return at;
  }

  Future<void> _scheduleWeekly() async {
    await notifications.schedule(
      id: weeklyId,
      at: nextWeeklyTime(),
      title: 'Your week in Daymark',
      // Computed now, shown on Sunday: the counts can be up to a week old.
      // They are refreshed every time the app is opened (reconcile).
      body: await weeklySummaryText(),
      payload: jsonEncode({'type': payloadType, 'kind': 'weekly'}),
      channel: NotificationChannels.digests,
      withActions: false,
      repeatMatching: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// "This week: 12 tasks done, 3 reminders missed" for the last 7 days.
  Future<String> weeklySummaryText() async {
    final userId = currentUserId();
    if (userId == 0) return 'Open Daymark to see how your week went.';
    final now = _now();
    final since = now.subtract(const Duration(days: 7));
    final sinceWall = wallClockOf(tz.TZDateTime.from(since, tz.local));
    final nowWall = wallClockOf(now);

    var tasksDone = 0;
    for (final task in await database.getTasksForUser(userId)) {
      final updated = DateTime.tryParse(task.updatedAt ?? '');
      if (task.status == ItemStatus.completed && updated != null && updated.isAfter(since)) {
        tasksDone++;
      }
    }

    var remindersMissed = 0;
    for (final row in await database.getRemindersForUser(userId)) {
      final reminder = ReminderDatabaseMapper.toReminderItem(row);
      if (_missedThisWeek(reminder, sinceWall, nowWall, now)) remindersMissed++;
    }

    String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
    return 'This week: ${plural(tasksDone, 'task')} done, '
        '${plural(remindersMissed, 'reminder')} missed';
  }

  static bool _missedThisWeek(ReminderItem reminder, DateTime since, DateTime until, DateTime now) {
    bool inWeek(String? value) {
      final at = parseWallClock(value);
      return at != null && at.isAfter(since) && !at.isAfter(until);
    }

    if (reminder.repeatInterval != 'NONE') {
      return reminder.lastOutcome == 'MISSED' && inWeek(reminder.lastOutcomeAt);
    }
    return reminder.effectiveStatus(now) == ItemStatus.missed && inWeek(reminder.remindAt);
  }
}
