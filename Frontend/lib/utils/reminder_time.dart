import 'package:timezone/timezone.dart' as tz;

/// Wall-clock reminder times (REM-03, REM-05).
///
/// `remindAt` / `startAt` are the date and time the user picked, with no
/// zone (`2026-11-26T18:00:00`). In Dart they are held in a [DateTime] in
/// UTC used only as a container: its fields are the wall clock, and UTC has
/// no DST, so building one never shifts the time (a local [DateTime] would
/// move 02:30 on a spring-forward day). They become a real instant only at
/// the last moment, in the device zone ([toTz]). Dates are built from their
/// parts and never shifted with a [Duration]; a reminder at 18:00 fires at
/// 18:00 local time wherever the user is (a calendar "floating" time).
///
/// Use [wallClock], [wallClockOf] or [wallClockFromLocal] to make one; never
/// compare one with `DateTime.now()` directly.

final _wallClock = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?');

/// Parses `yyyy-MM-ddTHH:mm[:ss]`; anything after the seconds (fraction,
/// `Z`, offset) is ignored. Null if it isn't a real date and time.
/// A wall-clock value (see the file comment).
DateTime wallClock(int year, int month, int day, [int hour = 0, int minute = 0, int second = 0]) =>
    DateTime.utc(year, month, day, hour, minute, second);

/// The wall-clock reading of a device-local [DateTime] (e.g. a picker value).
DateTime wallClockFromLocal(DateTime local) =>
    wallClock(local.year, local.month, local.day, local.hour, local.minute, local.second);

DateTime? parseWallClock(String? value) {
  if (value == null) return null;
  final match = _wallClock.firstMatch(value.trim());
  if (match == null) return null;
  final parts = [for (var i = 1; i <= 6; i++) int.parse(match.group(i) ?? '0')];
  final result = wallClock(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
  // DateTime rolls 2026-02-30 over to March; reject it instead.
  final valid = result.year == parts[0] &&
      result.month == parts[1] &&
      result.day == parts[2] &&
      result.hour == parts[3] &&
      result.minute == parts[4];
  return valid ? result : null;
}

String _two(int value) => value.toString().padLeft(2, '0');

/// `yyyy-MM-ddTHH:mm:ss`, as stored and sent to the server.
String formatWallClock(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${_two(value.month)}-${_two(value.day)}'
    'T${_two(value.hour)}:${_two(value.minute)}:${_two(value.second)}';

/// `yyyy-MM-dd` (the reminder's `dueDate`).
String formatDueDate(DateTime value) => formatWallClock(value).substring(0, 10);

/// `HH:mm` (the reminder's `dueTime`).
String formatDueTime(DateTime value) => formatWallClock(value).substring(11, 16);

/// Whether two stored wall-clock strings are the same moment
/// (`2026-11-26T18:00` equals `2026-11-26T18:00:00`).
bool sameWallClock(String? a, String? b) {
  final left = parseWallClock(a);
  final right = parseWallClock(b);
  return left != null && left == right;
}

/// The wall clock in [location]: builds the instant from its parts. A time
/// that doesn't exist (skipped by a DST change) moves forward by the gap.
tz.TZDateTime toTz(DateTime value, tz.Location location) => tz.TZDateTime(
  location,
  value.year,
  value.month,
  value.day,
  value.hour,
  value.minute,
  value.second,
);

/// The wall-clock reading of [instant] (its local date and time fields).
DateTime wallClockOf(tz.TZDateTime instant) => wallClock(
  instant.year,
  instant.month,
  instant.day,
  instant.hour,
  instant.minute,
  instant.second,
);

/// `6:00 PM` or `18:00`.
String formatDue(DateTime value, {required bool use24h}) {
  if (use24h) return '${_two(value.hour)}:${_two(value.minute)}';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '$hour:${_two(value.minute)} ${value.hour < 12 ? 'AM' : 'PM'}';
}

/// REM-05: the first occurrence of a series strictly after [after]; [start]
/// itself when [after] is earlier. Null for `NONE` (or an unknown interval).
///
/// - DAILY: same time every day.
/// - WEEKLY: same weekday and time.
/// - MONTHLY: same day of month as [start], clamped to the month's length
///   (31 Jan → 28/29 Feb → 31 Mar), always anchored to [start], never drifting.
///
/// All values are wall clock, built from their parts (see the file comment).
DateTime? nextOccurrence({
  required DateTime start,
  required String interval,
  required DateTime after,
}) {
  final normalized = interval.toUpperCase();
  if (!const {'DAILY', 'WEEKLY', 'MONTHLY'}.contains(normalized)) return null;
  if (after.isBefore(start)) return start;

  DateTime at(int year, int month, int day) =>
      wallClock(year, month, day, start.hour, start.minute, start.second);

  switch (normalized) {
    case 'DAILY':
      final today = at(after.year, after.month, after.day);
      return today.isAfter(after) ? today : at(after.year, after.month, after.day + 1);
    case 'WEEKLY':
      final ahead = (start.weekday - after.weekday) % 7;
      final candidate = at(after.year, after.month, after.day + ahead);
      return candidate.isAfter(after) ? candidate : at(after.year, after.month, after.day + ahead + 7);
    default: // MONTHLY
      var year = after.year;
      var month = after.month;
      while (true) {
        final candidate = at(year, month, _clampDay(year, month, start.day));
        if (candidate.isAfter(after)) return candidate;
        month++;
        if (month > 12) {
          month = 1;
          year++;
        }
      }
  }
}

int _clampDay(int year, int month, int day) {
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return day < lastDay ? day : lastDay;
}

/// "Repeats daily" etc., or null for one-off reminders.
String? repeatLabel(String interval) => switch (interval.toUpperCase()) {
  'DAILY' => 'Repeats daily',
  'WEEKLY' => 'Repeats weekly',
  'MONTHLY' => 'Repeats monthly',
  _ => null,
};
