# BE-04 — Reminder service: completed sort first, stale dueDate after edit, no validation

**Type:** Bug · **Priority:** P1 · **Area:** Backend · **Depends on:** none

## Problems
1. **Wrong sort.** `reminders/repository/ReminderRepository.java:13`: `ORDER BY r.status ASC, r.remindAt ASC`. Alphabetical status order is `COMPLETED, MISSED, PENDING, REJECTED`, so **completed reminders come first** and pending ones are buried.
2. **Stale date after edit.** `ReminderService.updateReminder` (`reminders/service/ReminderService.java`, the `if (requestDto.getRemindAt() != null) reminder.setRemindAt(...)` block) updates `remindAt` but **does not re-derive `dueDate`/`dueTime`**, unlike `createReminder`. The calendar and `get-by-date` keep showing the old day.
3. **No validation.** `status`, `repeatInterval`, `remindAt` format and `title` are free strings. `title` null → `nullable=false` constraint → 500. `updateStatus` upper-cases any string, so `status=foo` is stored. Same in `TaskService` for `status` and `priority`.
4. **Task un-complete edge case.** `TaskService.updateTask` sets `completed = isCompleted || status==COMPLETED`. A partial update with `isCompleted:false` and no `status` leaves the task completed, and `isCompleted:true` with `status:PENDING` leaves an inconsistent row. Derive `isCompleted` from `status` only (or the other way round) in one place.

## Proposed fix
- Order pending first: `ORDER BY CASE r.status WHEN 'PENDING' THEN 0 WHEN 'MISSED' THEN 1 WHEN 'COMPLETED' THEN 2 ELSE 3 END, r.remindAt ASC`. Do the same for tasks if useful.
- Pull the derivation into a private `applyRemindAt(reminder, remindAt, dueDate, dueTime)` used by both create and update. When `remindAt` changes and `dueDate`/`dueTime` aren't given explicitly, re-derive them.
- Add Java enums `ItemStatus {PENDING, COMPLETED, REJECTED, MISSED}`, `RepeatInterval {NONE, DAILY, WEEKLY, MONTHLY}` and `Priority {LOW, MEDIUM, HIGH}`. Keep `@Enumerated(EnumType.STRING)` so existing string values still map. Validate `remindAt` as `yyyy-MM-dd'T'HH:mm[:ss]`, `dueDate` as `yyyy-MM-dd` and `dueTime` as `HH:mm`. Return 400 on violation (BE-03).
- Tasks: `isCompleted = (status == COMPLETED)`, always.

## Acceptance criteria
- [ ] `get-all-reminders` returns pending before completed.
- [ ] Changing `remindAt` to another day moves the reminder in `get-by-date` and `calendar-summary`.
- [ ] Invalid status/interval/date → 400.
- [ ] Tests for each case.
