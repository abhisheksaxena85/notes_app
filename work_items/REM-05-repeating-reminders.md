# REM-05 — Repeating reminders move to the next occurrence

**Type:** Feature / bug · **Priority:** P1 · **Area:** Frontend + backend (REM-07) · **Depends on:** REM-03 · **Read:** REM-00

## Problem today
`repeatInterval` (NONE/DAILY/WEEKLY/MONTHLY) is stored but does nothing. `remindAt` never changes, so:
- marking a DAILY reminder completed keeps it completed forever;
- the calendar shows it only on the first day;
- `ReminderItem.effectiveStatus` (`data/network/dto/response/reminder/reminder_item.dart:28-38`) never shows a repeating reminder as missed, which hides the problem.

## Model
Add `startAt` (the first occurrence, wall-clock string) to the reminder, both locally (`CachedReminders`, nullable; migration fills it from `remindAt`) and on the server (REM-07). The series is defined by `startAt + repeatInterval`. `remindAt` always points to the **next pending occurrence**.

## Pure function `nextOccurrence` (in `lib/utils/reminder_time.dart`)
```dart
DateTime? nextOccurrence({
  required DateTime start,        // wall clock
  required String interval,       // DAILY | WEEKLY | MONTHLY | NONE
  required DateTime after,        // wall clock; returns first occurrence strictly after this
});
```
- DAILY: same time each day. WEEKLY: same weekday and time. MONTHLY: same day of month, **clamped** to the month's length (31 Jan → 28/29 Feb → 31 Mar; always anchored to `start.day`, never drifting).
- Build each candidate as a wall-clock `DateTime(y, m, d, h, min)` and never add a `Duration`, so DST changes don't shift the time.
- NONE → null.

## Behaviour
- `completeOccurrence(id, occurrence, outcome)` in `ReminderRepo` (local first, FE-02):
  - for repeating reminders: `remindAt = nextOccurrence(after: occurrence)`, status stays `PENDING`, clear `snoozedUntil`, and set optional `lastOutcome = outcome` and `lastOutcomeAt = occurrence` (used for the card subtitle "Last: done ✓");
  - queue a server mutation using REM-07's `complete-occurrence` endpoint (idempotent by `occurrence`).
- **Catch-up:** during reconcile (REM-03), if a repeating reminder's `remindAt` is in the past (the app was closed for days and nobody answered), advance it to the next future occurrence and set `lastOutcome = 'MISSED'`. Don't fire a burst of old notifications.
- The status chooser on the Workspace card (`item_status_sheet.dart`) for a repeating reminder offers "Done for today / Missed today / Stop repeating" instead of a permanent COMPLETED.
- Optional: the calendar projects future occurrences of repeating reminders within the visible month (`calendar_screen.dart` `_getRemindersForDate`) with a lighter badge.

## Acceptance criteria
- [ ] Unit tests for `nextOccurrence`: daily across month and year ends; weekly; monthly from the 31st across Feb (leap and non-leap) and April; a DST-change date in `America/New_York` using `timezone` test data; `after` equal to an occurrence returns the following one.
- [ ] Done on a DAILY 08:00 reminder → it shows tomorrow 08:00, pending, and the notification is scheduled for tomorrow.
- [ ] App closed for 3 days → on open, the reminder points to the next future 08:00, with no flood of notifications.
