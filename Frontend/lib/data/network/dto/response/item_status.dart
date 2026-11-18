/// Status values shared by tasks and reminders, plus the display rule that a
/// PENDING item whose due moment has passed is shown as MISSED.
class ItemStatus {
  static const pending = 'PENDING';
  static const completed = 'COMPLETED';
  static const rejected = 'REJECTED';
  static const missed = 'MISSED';

  /// Parses `YYYY-MM-DD` plus optional `HH:mm`. A date without a time is due
  /// at the end of that day, so it only turns MISSED once the day is over.
  static DateTime? dueMoment(String? date, String? time) {
    if (date == null || date.length < 10) return null;
    final day = DateTime.tryParse(date.substring(0, 10));
    if (day == null) return null;

    final parts = (time ?? '').split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (hour == null || minute == null) {
      return DateTime(day.year, day.month, day.day, 23, 59, 59);
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  static String effective(String status, DateTime? due, DateTime now) {
    if (status == pending && due != null && due.isBefore(now)) return missed;
    return status;
  }
}
