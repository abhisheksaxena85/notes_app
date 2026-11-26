import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/utils/date/date_keys.dart';

/// BE-02: timestamps are instants; offset-less values are UTC.
///
/// Expectations are computed with the test machine's zone, so they hold in
/// any zone. Run with `TZ=Asia/Kolkata flutter test` to see the midnight case.
void main() {
  DateTime dayOf(DateTime utc) {
    final local = utc.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  test('a Z timestamp lands on its local day', () {
    final utc = DateTime.utc(2026, 11, 25, 20);
    expect(DateKeys.localDay('2026-11-25T20:00:00Z'), dayOf(utc));
    expect(DateKeys.localDay('2026-11-25T20:00:00.000Z'), dayOf(utc));
  });

  test('an offset-less timestamp is read as UTC', () {
    expect(
      DateKeys.localDay('2026-11-25T20:00:00'),
      DateKeys.localDay('2026-11-25T20:00:00Z'),
    );
    expect(
      DateKeys.instant('2026-11-25T18:29:59.999'),
      DateTime.utc(2026, 11, 25, 18, 29, 59, 999).toLocal(),
    );
  });

  test('an explicit offset is honoured', () {
    // 01:30 on Nov 26 in India is 20:00 UTC on Nov 25.
    expect(
      DateKeys.instant('2026-11-26T01:30:00+05:30'),
      DateTime.utc(2026, 11, 25, 20).toLocal(),
    );
  });

  test('the same instant is on the same day before and after sync', () {
    // Written locally, then replaced by the server copy of the same instant.
    final created = DateTime.utc(2026, 11, 25, 20);
    final local = created.toIso8601String(); // what the app stores
    const server = '2026-11-25T20:00:00Z'; // what the server returns
    expect(DateKeys.localDay(local), DateKeys.localDay(server));
    expect(DateKeys.isOnDay(server, dayOf(created)), isTrue);
  });

  test('in India, 01:30 on Nov 26 is Nov 26 before and after sync', () {
    // 01:30 local is 20:00 UTC the day before.
    expect(DateKeys.localDay('2026-11-25T20:00:00Z'), DateTime(2026, 11, 26));
    expect(DateKeys.localDay('2026-11-25T20:00:00'), DateTime(2026, 11, 26));
    expect(DateKeys.localDay('2026-11-25T18:29:59.999Z'), DateTime(2026, 11, 25));
    expect(DateKeys.localDay('2026-11-25T18:30:00.000Z'), DateTime(2026, 11, 26));
  },
      skip: DateTime(2026, 11, 26).timeZoneOffset != const Duration(hours: 5, minutes: 30)
          ? 'needs TZ=Asia/Kolkata'
          : false);

  test('a bare date is that calendar day, never shifted', () {
    expect(DateKeys.localDay('2026-11-26'), DateTime(2026, 11, 26));
  });

  test('missing or unreadable values have no day', () {
    expect(DateKeys.localDay(null), isNull);
    expect(DateKeys.localDay('  '), isNull);
    expect(DateKeys.localDay('yesterday'), isNull);
    expect(DateKeys.isOnDay(null, DateTime(2026, 11, 26)), isFalse);
  });

  test('nowUtc writes a UTC instant', () {
    expect(DateKeys.nowUtc(), endsWith('Z'));
  });
}
