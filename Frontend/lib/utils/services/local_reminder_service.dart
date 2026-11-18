import 'package:flutter/material.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';

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

  static Future<void> setDailyReminder(bool enabled, {TimeOfDay? time}) async {
    final pref = getIt<Preference>();
    await pref.setBool(keyDailyReminder, enabled);
    if (time != null) {
      await pref.setString(
        keyDailyReminderTime,
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
      );
    }
  }

  static bool isWeeklySummaryEnabled() {
    return getIt<Preference>().getBool(keyWeeklySummary) ?? false;
  }

  static Future<void> setWeeklySummary(bool enabled) async {
    final pref = getIt<Preference>();
    await pref.setBool(keyWeeklySummary, enabled);
  }
}
