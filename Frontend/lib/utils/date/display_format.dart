/// Human-readable dates and times for the UI ("Friday, 27 November",
/// "10:30 AM", "2h ago"). Storage formats live in [DateKeys] and
/// reminder_time.dart; this file only formats for display.
class DisplayFormat {
  DisplayFormat._();

  static const weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _shortMonth(int month) => months[month - 1].substring(0, 3);

  /// "Friday, 27 November".
  static String longDate(DateTime day) =>
      '${weekdays[day.weekday - 1]}, ${day.day} ${months[day.month - 1]}';

  /// "27 Nov".
  static String shortDate(DateTime day) => '${day.day} ${_shortMonth(day.month)}';

  /// "Fri, 27 Nov 2026" for date fields.
  static String fieldDate(DateTime day) =>
      '${weekdays[day.weekday - 1].substring(0, 3)}, ${day.day} ${_shortMonth(day.month)} ${day.year}';

  /// "November 2026".
  static String monthYear(DateTime day) => '${months[day.month - 1]} ${day.year}';

  /// "Good morning" / "Good afternoon" / "Good evening".
  static String greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// "10:30 AM" from an hour and minute.
  static String time(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }

  /// "10:30 AM" from a stored "HH:mm" (or "HH:mm:ss"); the input unchanged
  /// if it can't be read.
  static String clock(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return hhmm;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return hhmm;
    return time(hour, minute);
  }

  /// A stored "YYYY-MM-DD" as a local day, or null.
  static DateTime? day(String? ymd) {
    if (ymd == null || ymd.length < 10) return null;
    final parsed = DateTime.tryParse(ymd.substring(0, 10));
    return parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// When something is due: "10:30 AM" today, "Tomorrow · 10:30 AM",
  /// "28 Nov · 10:30 AM", or just the date or time that is set.
  static String due(String? dueDate, String? dueTime, [DateTime? now]) {
    final today = now ?? DateTime.now();
    final date = day(dueDate);
    final hasTime = dueTime != null && dueTime.trim().isNotEmpty;
    final timeText = hasTime ? clock(dueTime.trim()) : null;
    if (date == null) return timeText ?? (dueDate ?? '');
    final String dateText;
    if (sameDay(date, today)) {
      dateText = 'Today';
    } else if (sameDay(date, DateTime(today.year, today.month, today.day + 1))) {
      dateText = 'Tomorrow';
    } else if (sameDay(date, DateTime(today.year, today.month, today.day - 1))) {
      dateText = 'Yesterday';
    } else {
      dateText = date.year == today.year
          ? shortDate(date)
          : '${shortDate(date)} ${date.year}';
    }
    if (timeText == null) return dateText;
    return dateText == 'Today' ? timeText : '$dateText · $timeText';
  }

  /// "Just now", "5m ago", "2h ago", "Yesterday", "24 Nov".
  static String relative(DateTime moment, [DateTime? now]) {
    final current = now ?? DateTime.now();
    final diff = current.difference(moment);
    if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (sameDay(moment, current)) return '${diff.inHours}h ago';
    final yesterday = DateTime(current.year, current.month, current.day - 1);
    if (sameDay(moment, yesterday)) return 'Yesterday';
    return moment.year == current.year
        ? shortDate(moment)
        : '${shortDate(moment)} ${moment.year}';
  }

  /// Up to two initials from a name ("Ada Lovelace" → "AL").
  static String initials(String? name) {
    final words = (name ?? '').trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    final first = words.first[0];
    final last = words.length > 1 ? words.last[0] : '';
    return (first + last).toUpperCase();
  }
}
