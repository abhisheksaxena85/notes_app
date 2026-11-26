import 'package:flutter/material.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';

/// The "Daily reminder" and "Weekly summary" settings, stored on this
/// device. DigestScheduler (REM-08) schedules the notifications for them.
class LocalReminderService {
  static const String keyDailyReminder = "daily_reminder_enabled";
  static const String keyDailyReminderTime = "daily_reminder_time";
  static const String keyWeeklySummary = "weekly_summary_enabled";

  static bool isDailyReminderEnabled() {
    return getIt<Preference>().getBool(keyDailyReminder) ?? false;
  }

  static TimeOfDay getDailyReminderTime() {
    final timeStr = getIt<Preference>().getString(keyDailyReminderTime);
    if (timeStr != null && timeStr.contains(':')) {
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  static Future<void> setDailyReminder(bool enabled, {TimeOfDay? time}) =>
      save(getIt<Preference>(), daily: enabled, dailyTime: time);

  static bool isWeeklySummaryEnabled() {
    return getIt<Preference>().getBool(keyWeeklySummary) ?? false;
  }

  static Future<void> setWeeklySummary(bool enabled) =>
      save(getIt<Preference>(), weekly: enabled);

  /// Saves whichever settings are given.
  static Future<void> save(
    Preference pref, {
    bool? daily,
    TimeOfDay? dailyTime,
    bool? weekly,
  }) async {
    if (daily != null) await pref.setBool(keyDailyReminder, daily);
    if (dailyTime != null) {
      await pref.setString(
        keyDailyReminderTime,
        "${dailyTime.hour.toString().padLeft(2, '0')}:${dailyTime.minute.toString().padLeft(2, '0')}",
      );
    }
    if (weekly != null) await pref.setBool(keyWeeklySummary, weekly);
  }
}
