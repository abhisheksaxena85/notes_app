# REM-06 — Edit-reminder UI and no past times on create

**Type:** Feature / bug · **Priority:** P1 · **Area:** Frontend · **Depends on:** FE-02, REM-03

## Problems
1. Reminders can't be edited: `home_screen.dart` doesn't wire `onTap` for `reminderItemCard`, and there's no edit form. `ReminderRepo.updateReminder` (`reminder_repo.dart:152-165`) only works online for synced reminders. For unsynced ones (negative id) it does nothing.
2. `create_reminder_modal.dart` lets you pick **today with a time that has already passed** (the date picker blocks past days but the time picker isn't checked, see `_saveReminder` ~72-110). The reminder is born overdue and immediately shows as missed.
3. The modal shows raw exceptions (`'Failed to create reminder: $e'`).

## Tasks
1. Turn `CreateReminderModal` into `ReminderFormModal({ReminderItem? initial})`, used for both create and edit (title, date, time, repeat, category). Show a "Delete" action in edit mode.
2. Validation: when the chosen date is today, the time must be ≥ now + 1 min. Show an inline error under the time field. For repeating reminders a past start is allowed only if the next occurrence is computed (REM-05). Keep it simple: require a future first occurrence.
3. `ReminderRepo.updateReminder` goes local first through FE-02 (works offline and for unsynced items). Changing `remindAt` also updates `dueDate`/`dueTime` locally (same derivation as create) and clears `snoozedUntil`. The watch stream triggers REM-03's reconcile, which reschedules.
4. Wire `onTap` on the reminder card to open the form in edit mode.
5. Show a small bell icon on the card: filled when a notification is scheduled, struck through when notifications are off (from the REM-02 permission status). This helps users trust the feature.
6. Friendly errors (FE-06 helper).

## Acceptance criteria
- [ ] Create: picking a past time today shows the inline error and doesn't save.
- [ ] Edit an unsynced reminder offline: the change shows at once, is rescheduled, and syncs later as one create with the final values.
- [ ] Edit a synced reminder's time: the notification moves to the new time. The server is updated (after reconnecting if offline).
- [ ] Widget tests for validation and edit-mode prefill.
