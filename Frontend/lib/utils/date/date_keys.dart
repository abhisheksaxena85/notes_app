/// Turning stored timestamps into calendar days (BE-02).
///
/// `createdAt` / `updatedAt` are instants: ISO-8601 in UTC, e.g.
/// `2026-11-25T20:00:00Z`. A value without an offset (written by older server
/// and app versions) is read as UTC too. Use [localDay] wherever such a value
/// becomes a day, so an item shows on the day it was made *here*.
///
/// Task `dueDate`/`dueTime` and reminder `remindAt` are not instants: they are
/// the wall-clock values the user picked, and are never converted.
class DateKeys {
  DateKeys._();

  /// [iso] as a moment in the device's time zone, or null if it can't be
  /// parsed. A bare date (`YYYY-MM-DD`) is that day at local midnight.
  static DateTime? instant(String? iso) {
    final value = iso?.trim() ?? '';
    if (value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    if (value.length <= 10) return parsed; // a date, not a timestamp
    if (parsed.isUtc) return parsed.toLocal(); // had `Z` or an offset
    // No offset: the fields are UTC.
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).toLocal();
  }

  /// The local calendar day (midnight) of the timestamp [iso].
  static DateTime? localDay(String? iso) {
    final local = instant(iso);
    if (local == null) return null;
    return DateTime(local.year, local.month, local.day);
  }

  /// Whether the timestamp [iso] falls on [day] in the device's time zone.
  static bool isOnDay(String? iso, DateTime day) {
    final local = localDay(iso);
    return local != null &&
        local.year == day.year &&
        local.month == day.month &&
        local.day == day.day;
  }

  /// Now, as written to `createdAt` / `updatedAt`.
  static String nowUtc() => DateTime.now().toUtc().toIso8601String();
}
