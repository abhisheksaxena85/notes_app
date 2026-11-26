# BE-02 — Server timestamps use server-local time, so items land on the wrong calendar day

**Type:** Bug · **Priority:** P1 · **Area:** Backend + Frontend · **Depends on:** none

## Problem
All `createdAt` / `updatedAt` values are generated with `LocalDateTime.now().toString()` (13 places in `Backend/src/main/java`, for example `NotesService.java:90-91`). That's wall-clock time **in the server's zone** (UTC on Railway) with **no offset**, such as `2026-11-25T20:45:00`.

The app groups notes by calendar day using the first 10 characters of `createdAt` (`Frontend/lib/views/screens/calendar/calendar_screen.dart:46-67`; backend `NotesService.getCalendarSummary` and `NotesRepository.findByUserIdAndDatePrefix` do the same).

Example for a user in India (UTC+5:30):
1. They create a note at 01:30 on Nov 26. Offline, the local row gets `createdAt=2026-11-26T01:30…` and appears on **Nov 26**.
2. After sync, `replaceServerNotes` replaces it with the server copy, `createdAt=2026-11-25T20:00:00`, and the note **moves to Nov 25**. `get-notes-by-date` and `calendar-summary` agree with that wrong day.

Also, the client's own local `createdAt` (sent in the payload for imports) is ignored on create.

## Proposed fix
1. Backend: store an absolute instant. Simplest: keep the `String` columns but write `Instant.now().toString()` (`2026-11-25T20:00:00Z`). Better: switch the columns to `Instant`/`OffsetDateTime` (needs a migration). Treat existing offset-less values as UTC.
2. Backend date filters (`calendar-summary`, `get-notes-by-date`, `day-activity`) need the client's zone. Accept a `tz` query param (IANA name, such as `Asia/Kolkata`) and bucket by `instant.atZone(tz).toLocalDate()`. Or drop server-side bucketing and let the client do it (the calendar already computes locally).
3. Frontend: wherever a timestamp is turned into a day (`calendar_screen.dart` `_getNotesForDate` / `_getTasksForDate`, note cards, `note_meta_info_widget.dart`, exports), parse with `DateTime.parse(s).toLocal()` instead of `substring(0,10)`. Add one helper, for example `DateKeys.localDay(String iso)`, and use it everywhere.
4. Tasks `dueDate`/`dueTime` and reminders `remindAt` are **user-chosen wall-clock values** and should stay local (no conversion). Document this distinction in `docs/API_MAPPING.md`.
5. Optional: accept a client-provided `createdAt` on create (for imports and offline creates) when present and valid.

## Acceptance criteria
- [ ] A note created at 01:30 local in UTC+5:30 shows on the same day before and after sync.
- [ ] Backend tests cover bucketing with `tz=Asia/Kolkata` around midnight.
- [ ] Frontend test for the `localDay` helper with `Z` and offset-less inputs.
