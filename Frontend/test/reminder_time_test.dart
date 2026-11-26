import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// REM-03 / REM-05: wall-clock parsing, formatting and repeat occurrences.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  DateTime w(String value) => parseWallClock(value)!;

  group('parseWallClock', () {
    test('accepts minutes or seconds and ignores any suffix', () {
      expect(parseWallClock('2026-11-26T18:00'), wallClock(2026, 11, 26, 18));
      expect(parseWallClock('2026-11-26T18:00:30'), wallClock(2026, 11, 26, 18, 0, 30));
      expect(parseWallClock('2026-11-26T18:00:00.000Z'), wallClock(2026, 11, 26, 18));
      expect(parseWallClock('2026-11-26T18:00:00+05:30'), wallClock(2026, 11, 26, 18),
          reason: 'the offset is ignored: it is a wall-clock time');
    });

    test('rejects impossible or malformed values', () {
      expect(parseWallClock('2026-02-30T09:00:00'), isNull);
      expect(parseWallClock('2026-11-26T25:00:00'), isNull);
      expect(parseWallClock('26/11/2026 18:00'), isNull);
      expect(parseWallClock(''), isNull);
      expect(parseWallClock(null), isNull);
    });

    test('is not shifted by the host time zone on a DST day', () {
      // 02:30 doesn't exist in New York on 2026-03-08; a wall-clock value
      // must still read back as 02:30.
      expect(formatWallClock(w('2026-03-08T02:30:00')), '2026-03-08T02:30:00');
    });

    test('sameWallClock compares moments, not strings', () {
      expect(sameWallClock('2026-11-26T18:00', '2026-11-26T18:00:00'), isTrue);
      expect(sameWallClock('2026-11-26T18:00', '2026-11-26T18:01:00'), isFalse);
      expect(sameWallClock(null, null), isFalse);
    });
  });

  test('formatDue in 12 and 24 hours', () {
    expect(formatDue(w('2026-11-26T18:05:00'), use24h: false), '6:05 PM');
    expect(formatDue(w('2026-11-26T00:30:00'), use24h: false), '12:30 AM');
    expect(formatDue(w('2026-11-26T12:00:00'), use24h: false), '12:00 PM');
    expect(formatDue(w('2026-11-26T18:05:00'), use24h: true), '18:05');
  });

  test('due date and time derived from a wall clock', () {
    expect(formatDueDate(w('2026-01-05T07:09:00')), '2026-01-05');
    expect(formatDueTime(w('2026-01-05T07:09:00')), '07:09');
  });

  group('nextOccurrence', () {
    DateTime? next(String start, String interval, String after) =>
        nextOccurrence(start: w(start), interval: interval, after: w(after));

    test('NONE and unknown intervals have none', () {
      expect(next('2026-01-01T08:00', 'NONE', '2026-01-01T08:00'), isNull);
      expect(next('2026-01-01T08:00', 'HOURLY', '2026-01-01T08:00'), isNull);
    });

    test('before the start, the start is next', () {
      expect(next('2026-03-10T08:00', 'DAILY', '2026-03-01T00:00'), w('2026-03-10T08:00'));
    });

    test('daily across month and year ends', () {
      expect(next('2026-01-01T08:00', 'DAILY', '2026-01-31T08:00'), w('2026-02-01T08:00'));
      expect(next('2026-12-01T08:00', 'DAILY', '2026-12-31T08:00'), w('2027-01-01T08:00'));
      expect(next('2026-02-01T08:00', 'DAILY', '2028-02-28T09:00'), w('2028-02-29T08:00'));
      expect(next('2026-05-01T08:00', 'DAILY', '2026-05-05T07:59'), w('2026-05-05T08:00'));
    });

    test('after equal to an occurrence returns the following one', () {
      expect(next('2026-01-01T08:00', 'DAILY', '2026-01-01T08:00'), w('2026-01-02T08:00'));
      expect(next('2026-01-01T08:00', 'WEEKLY', '2026-01-01T08:00'), w('2026-01-08T08:00'));
      expect(next('2026-01-01T08:00', 'MONTHLY', '2026-01-01T08:00'), w('2026-02-01T08:00'));
    });

    test('weekly keeps the weekday', () {
      // 2026-11-26 is a Thursday.
      expect(next('2026-11-26T18:00', 'WEEKLY', '2026-11-28T10:00'), w('2026-12-03T18:00'));
      expect(next('2026-11-26T18:00', 'WEEKLY', '2026-12-31T18:00'), w('2027-01-07T18:00'));
      expect(next('2026-11-26T18:00', 'weekly', '2026-12-31T17:59'), w('2026-12-31T18:00'));
    });

    test('monthly from the 31st clamps and keeps the anchor', () {
      const start = '2026-01-31T09:00';
      expect(next(start, 'MONTHLY', start), w('2026-02-28T09:00'));
      expect(next(start, 'MONTHLY', '2026-02-28T09:00'), w('2026-03-31T09:00'));
      expect(next(start, 'MONTHLY', '2026-03-31T09:00'), w('2026-04-30T09:00'));
      expect(next(start, 'MONTHLY', '2026-04-30T09:00'), w('2026-05-31T09:00'));
      // Leap year.
      expect(next('2028-01-31T09:00', 'MONTHLY', '2028-01-31T09:00'), w('2028-02-29T09:00'));
      // Year end.
      expect(next('2026-06-30T12:00', 'MONTHLY', '2026-12-30T12:00'), w('2027-01-30T12:00'));
    });

    test('DST in America/New_York keeps the local time of day', () {
      final ny = tz.getLocation('America/New_York');
      // US DST starts 2026-03-08 02:00.
      final before = toTz(next('2026-03-01T08:00', 'DAILY', '2026-03-06T08:00')!, ny);
      final after = toTz(next('2026-03-01T08:00', 'DAILY', '2026-03-07T08:00')!, ny);
      expect((before.hour, after.hour), (8, 8));
      expect(after.difference(before), const Duration(hours: 23),
          reason: 'the clock moved, the reminder did not');

      // And back in November (2026-11-01 02:00).
      final fallBefore = toTz(w('2026-10-31T08:00'), ny);
      final fallAfter = toTz(next('2026-10-01T08:00', 'DAILY', '2026-10-31T08:00')!, ny);
      expect(fallAfter.hour, 8);
      expect(fallAfter.difference(fallBefore), const Duration(hours: 25));
    });

    test('a time skipped by DST fires right after the gap', () {
      final ny = tz.getLocation('America/New_York');
      final skipped = toTz(next('2026-03-01T02:30', 'DAILY', '2026-03-07T02:30')!, ny);
      expect(skipped.day, 8);
      expect(skipped.hour, 3);
      expect(skipped.minute, 30);
    });
  });
}
