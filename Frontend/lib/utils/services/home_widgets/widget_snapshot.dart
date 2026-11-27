import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:timezone/timezone.dart' as tz;

/// The data the home-screen widgets show (W-01), written by
/// [WidgetSnapshotService] as one JSON string under [WidgetSnapshot.storageKey].
///
/// Native widgets (Glance on Android, WidgetKit on iOS) only render it, so
/// everything time-dependent is sent as epoch milliseconds: they decide
/// "overdue", "Tomorrow, 9:00 AM" and which reminder is next at render time,
/// which keeps them right after the time passes without the app running.
///
/// Format (version [version]):
/// ```json
/// {
///   "v": 1, "loggedIn": true, "generatedAt": 1764230400000,
///   "tasks": {
///     "count": 7,                     // every task in the list, not only items
///     "items": [{"id": -4, "title": "Call Sam", "dueAt": 1764252000000,
///                "hasTime": true, "overdue": false}]   // dueAt null = undated
///   },
///   "reminders": [{"id": 12, "title": "Stretch", "fireAt": 1764262800000,
///                  "occurrence": "2026-11-27T18:00:00", "repeat": "DAILY",
///                  "snoozed": false}]
/// }
/// ```
/// A signed-out snapshot is `{"v": 1, "loggedIn": false, ...}` with empty lists.
@immutable
class WidgetSnapshot {
  static const version = 1;

  /// The home_widget key (SharedPreferences on Android, the App Group
  /// UserDefaults on iOS).
  static const storageKey = 'daymark_widget_snapshot';

  /// Enough rows for the large Tasks widget (6) twice over.
  static const maxTasks = 12;

  /// Upcoming reminder occurrences: the next one, the following one, and
  /// spares so the widget can roll over while the app isn't running.
  static const maxReminders = 5;

  final bool loggedIn;
  final DateTime generatedAt;
  final int taskCount;
  final List<WidgetTask> tasks;
  final List<WidgetReminder> reminders;

  const WidgetSnapshot({
    required this.loggedIn,
    required this.generatedAt,
    this.taskCount = 0,
    this.tasks = const [],
    this.reminders = const [],
  });

  factory WidgetSnapshot.loggedOut(DateTime now) =>
      WidgetSnapshot(loggedIn: false, generatedAt: now);

  /// Builds the signed-in snapshot from the user's cached rows.
  ///
  /// Tasks: pending ones that are overdue or due today, by due moment, then
  /// undated pending ones in creation order. Tasks due on a later day, and
  /// completed / missed / rejected ones, are left out.
  ///
  /// Reminders: the next [maxReminders] occurrences by real fire time: a
  /// snooze wins over the scheduled time, and a repeating reminder whose
  /// stored occurrence has passed (not caught up yet) continues with its next
  /// occurrence (REM-05). A repeating series contributes each of its
  /// occurrences, so the widget still has the right "next" after one passes.
  factory WidgetSnapshot.build({
    required List<CachedTask> tasks,
    required List<CachedReminder> reminders,
    required tz.TZDateTime now,
  }) {
    final listed = _listedTasks(tasks, now);
    return WidgetSnapshot(
      loggedIn: true,
      generatedAt: now,
      taskCount: listed.length,
      tasks: listed.take(maxTasks).toList(),
      reminders: upcomingReminders(reminders, now, limit: maxReminders),
    );
  }

  static List<WidgetTask> _listedTasks(List<CachedTask> rows, tz.TZDateTime now) {
    final today = wallClock(now.year, now.month, now.day);
    final tomorrow = wallClock(now.year, now.month, now.day + 1);
    final dated = <(DateTime, WidgetTask)>[];
    final undated = <(int, WidgetTask)>[];
    for (final row in rows) {
      if (row.isDeleted || row.isCompleted || row.status != 'PENDING') continue;
      final id = row.serverId ?? -row.id;
      final day = _parseDate(row.dueDate);
      if (day == null) {
        undated.add((row.id, WidgetTask(id: id, title: row.title)));
        continue;
      }
      if (!day.isBefore(tomorrow)) continue; // a later day
      final time = _parseTime(row.dueTime);
      // Like ItemStatus.dueMoment: a date without a time is due at the end of it.
      final due = time == null
          ? wallClock(day.year, day.month, day.day, 23, 59, 59)
          : wallClock(day.year, day.month, day.day, time.$1, time.$2);
      final dueAt = toTz(due, now.location);
      final overdue = day.isBefore(today) || (time != null && !dueAt.isAfter(now));
      dated.add((
        due,
        WidgetTask(id: id, title: row.title, dueAt: dueAt, hasTime: time != null, overdue: overdue),
      ));
    }
    dated.sort((a, b) => a.$1.compareTo(b.$1));
    undated.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final d in dated) d.$2, for (final u in undated) u.$2];
  }

  /// The next [limit] reminder occurrences after [now], soonest first.
  static List<WidgetReminder> upcomingReminders(
    List<CachedReminder> rows,
    tz.TZDateTime now, {
    int limit = maxReminders,
  }) {
    final all = <WidgetReminder>[];
    for (final row in rows) {
      if (row.isDeleted || row.status != 'PENDING') continue;
      var next = nextFire(row, now);
      // Each reminder adds at most [limit] occurrences: never more are kept.
      for (var i = 0; next != null && i < limit; i++) {
        all.add(next);
        next = next.repeat == null ? null : _following(row, next, now);
      }
    }
    all.sort((a, b) {
      final byTime = a.fireAt.compareTo(b.fireAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return all.take(limit).toList();
  }

  /// The next time [row] really fires after [now], or null if it never does
  /// again (answered, or a one-off in the past). Matches what
  /// ReminderScheduler schedules, plus the catch-up it applies to repeats.
  static WidgetReminder? nextFire(CachedReminder row, tz.TZDateTime now) {
    if (row.isDeleted || row.status != 'PENDING') return null;
    final at = parseWallClock(row.remindAt);
    if (at == null) return null;
    final repeat = _repeatOf(row.repeatInterval);
    final snoozed = DateTime.tryParse(row.snoozedUntil ?? '');
    if (snoozed != null && snoozed.isAfter(now)) {
      return WidgetReminder.of(row, tz.TZDateTime.from(snoozed, now.location),
          occurrence: row.remindAt, repeat: repeat, snoozed: true);
    }
    final scheduled = toTz(at, now.location);
    if (scheduled.isAfter(now)) {
      return WidgetReminder.of(row, scheduled, occurrence: row.remindAt, repeat: repeat);
    }
    if (repeat == null) return null;
    final next = nextOccurrence(
      start: parseWallClock(row.startAt) ?? at,
      interval: repeat,
      after: wallClockOf(now),
    );
    if (next == null) return null;
    return WidgetReminder.of(row, toTz(next, now.location),
        occurrence: formatWallClock(next), repeat: repeat);
  }

  /// The occurrence after [current], and never one that has passed (a
  /// snoozed occurrence can be older than now).
  static WidgetReminder? _following(CachedReminder row, WidgetReminder current, tz.TZDateTime now) {
    final at = parseWallClock(current.occurrence);
    final start = parseWallClock(row.startAt) ?? parseWallClock(row.remindAt);
    if (at == null || start == null) return null;
    final nowWall = wallClockOf(now);
    final after = at.isAfter(nowWall) ? at : nowWall;
    final next = nextOccurrence(start: start, interval: current.repeat!, after: after);
    if (next == null) return null;
    return WidgetReminder.of(row, toTz(next, now.location),
        occurrence: formatWallClock(next), repeat: current.repeat);
  }

  static String? _repeatOf(String interval) {
    final value = interval.toUpperCase();
    return const {'DAILY', 'WEEKLY', 'MONTHLY'}.contains(value) ? value : null;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.length < 10) return null;
    return parseWallClock('${value.substring(0, 10)}T00:00');
  }

  static (int, int)? _parseTime(String? value) {
    final parts = (value ?? '').split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  Map<String, Object?> toJson() => {
    'v': version,
    'loggedIn': loggedIn,
    'generatedAt': generatedAt.millisecondsSinceEpoch,
    'tasks': {
      'count': taskCount,
      'items': [for (final task in tasks) task.toJson()],
    },
    'reminders': [for (final reminder in reminders) reminder.toJson()],
  };

  String encode() => jsonEncode(toJson());
}

@immutable
class WidgetTask {
  /// The item id the app uses (server id, or minus the local id).
  final int id;
  final String title;

  /// Null for an undated task.
  final DateTime? dueAt;

  /// False when only a date was set (due at the end of that day).
  final bool hasTime;
  final bool overdue;

  const WidgetTask({
    required this.id,
    required this.title,
    this.dueAt,
    this.hasTime = false,
    this.overdue = false,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'dueAt': dueAt?.millisecondsSinceEpoch,
    'hasTime': hasTime,
    'overdue': overdue,
  };
}

@immutable
class WidgetReminder {
  /// The item id the app uses (server id, or minus the local id).
  final int id;
  final String title;

  /// When it fires (the snooze end for a snoozed one).
  final DateTime fireAt;

  /// The occurrence this is (wall clock, as stored in `remindAt`). "Done" on
  /// the widget answers exactly this one (REM-04 idempotency).
  final String occurrence;

  /// DAILY / WEEKLY / MONTHLY, or null for a one-off.
  final String? repeat;
  final bool snoozed;

  const WidgetReminder({
    required this.id,
    required this.title,
    required this.fireAt,
    required this.occurrence,
    this.repeat,
    this.snoozed = false,
  });

  factory WidgetReminder.of(
    CachedReminder row,
    DateTime fireAt, {
    required String occurrence,
    String? repeat,
    bool snoozed = false,
  }) => WidgetReminder(
    id: ReminderRepo.itemIdOf(row),
    title: row.title,
    fireAt: fireAt,
    occurrence: formatWallClock(parseWallClock(occurrence) ?? fireAt),
    repeat: repeat,
    snoozed: snoozed,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'fireAt': fireAt.millisecondsSinceEpoch,
    'occurrence': occurrence,
    'repeat': repeat,
    'snoozed': snoozed,
  };
}
