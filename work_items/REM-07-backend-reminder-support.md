# REM-07 — Backend support: status enum, occurrence fields, idempotency

**Type:** Feature · **Priority:** P1 · **Area:** Backend · **Depends on:** BE-04 (validation and sort fixes). Coordinate with FE-03 (`clientId`) and SEC-01 (ownership).

## Changes
1. **Model `ReminderModel`** (`reminders/model/ReminderModel.java`): add
   - `startAt` (String, wall clock): first occurrence. Backfill `= remind_at` for existing rows.
   - `lastOutcome` (enum `COMPLETED|MISSED`, nullable), `lastOutcomeAt` (String, nullable).
   - `clientId` (VARCHAR(36), nullable, unique with `user_id`) for idempotent creates (FE-03).
   - Use enums from BE-04 for `status` and `repeatInterval`.
2. **Create:** accept `startAt` (default `remindAt`) and `clientId`. If `(user, clientId)` already exists, return the existing id (200).
3. **New endpoint** `PUT /reminders/complete-occurrence` with body `{ reminderId, occurrence, outcome: COMPLETED|MISSED }`:
   - one-off (`NONE`): set `status = outcome`.
   - repeating: **only if `remindAt == occurrence`**, advance `remindAt` to the next occurrence (same rules as REM-05: wall clock, monthly clamping anchored to `startAt` day), update `dueDate`/`dueTime`, set `lastOutcome`/`lastOutcomeAt`, keep `PENDING`. If `remindAt != occurrence`, the occurrence was already handled: return the current entity unchanged (**idempotent**).
   - Returns the updated `ReminderModel`.
   - Put the date math in `reminders/service/RecurrenceCalculator.java` and unit-test it with the same cases as REM-05.
4. **Update:** when `remindAt` changes on a repeating reminder without an explicit `startAt`, treat the new value as a new `startAt` (the user re-anchored the series).
5. Update `docs/API_MAPPING.md` with the reminder endpoints (tasks and reminders are missing from it today).

## Acceptance criteria
- [ ] Calling `complete-occurrence` twice with the same occurrence advances once.
- [ ] Monthly from Jan 31 → Feb 28 → Mar 31 (anchor kept).
- [ ] Duplicate create with the same `clientId` returns the same id and doesn't insert a second row.
- [ ] Existing clients that don't send the new fields still work.
- [ ] `./mvnw test` passes with the new tests.
