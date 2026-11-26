# REM-00 — Feature overview: real reminders with system notifications

Read this before any REM-xx item. It sets the design those items follow.

## Goal
When a reminder's time arrives, the OS shows a notification **even if the app is closed or the phone is locked**. The user can answer straight from the notification:

| Action | Result (one-off reminder) | Result (repeating reminder) |
|---|---|---|
| **Done** | status → `COMPLETED` | this occurrence recorded as done; reminder moves to the next occurrence, stays `PENDING` |
| **Not done** | status → `MISSED` | this occurrence recorded as missed; moves to the next occurrence |
| **Snooze 10 min** | notification comes back in 10 min; status unchanged | same |
| Tap the notification body | app opens on the reminder with a "Did you do it?" sheet (Done / Not done / Snooze) | same |

The answer must stick **offline and with the app killed**. It's written locally, synced later (FE-02 outbox), and shown on the Workspace card (green strip and strikethrough for completed, red for missed; this UI already exists in `reminder_item_card.dart`).

> **Product decision to confirm:** "Not done" maps to `MISSED` (red). If you'd rather use `REJECTED`, or leave the reminder `PENDING` and only dismiss, change it in one place: `ReminderActionHandler`, see REM-04.

## Current state (from the audit)
- Reminders can be created (`create_reminder_modal.dart`), are stored in Drift (`CachedReminders`) and synced to `/reminders/*`. Nothing ever **fires**. There's no notification plugin in `pubspec.yaml`.
- `LocalReminderService` (`utils/services/local_reminder_service.dart`) only saves the "Daily reminder" and "Weekly summary" toggles in prefs. They do nothing (REM-08).
- Repeating reminders (`repeatInterval` DAILY/WEEKLY/MONTHLY) never advance. A completed DAILY reminder stays completed forever (REM-05).
- Reminders can't be edited from the UI, and `ReminderRepo.updateReminder` does nothing for unsynced reminders (REM-06, FE-02).

## Platform scope
- **Android and iOS:** full support (scheduled notifications plus actions).
- **macOS:** supported by the same plugin. Do it if cheap, otherwise make it a no-op.
- **Web, Windows, Linux:** `NotificationService` is a no-op that returns `supported = false`. The UI hides notification settings. Don't crash.

## Architecture
```
            ┌──────────────── Flutter (main isolate) ────────────────┐
 UI ──► ReminderViewmodel ──► ReminderRepo (local first, FE-02) ──► Drift
                                                     │ watch stream (debounced)
                                                     ▼
                                           ReminderScheduler.reconcile()
                                                     │
                                                     ▼
                                           NotificationService (wrapper around
                                           flutter_local_notifications + timezone)
                                                     │ zonedSchedule / cancel
                                                     ▼
                                              OS notification
                                                     │ user taps an action
         ┌───────────────────────────────────────────┴───────────────────────┐
  app running: onDidReceiveNotificationResponse        app killed / background:
                                                        @pragma('vm:entry-point')
                                                        notificationTapBackground()
         └──────────────► ReminderActionHandler.handle(response) ◄──────────┘
                           (idempotent; writes Drift + outbox; reschedules)
```

### Key decisions
1. **Notification id = local `CachedReminders.id`.** This needs FE-04 so the id survives cache refreshes. Ids 900001+ are reserved for the daily and weekly digests (REM-08).
2. **Payload** (JSON string): `{"v":1,"type":"reminder","userId":12,"localId":34,"serverId":567,"occurrence":"2026-11-26T18:00:00"}`. `occurrence` makes action handling **idempotent**. If the reminder has already moved past that occurrence, a second tap is ignored.
3. **Schedule one occurrence per reminder only** (the next one), not `matchDateTimeComponents`. Monthly repeats aren't supported by matching, and each occurrence needs its own state. After an action, or on reconcile, the next occurrence is scheduled.
4. **Reconcile, don't patch.** `ReminderScheduler.reconcile(userId)` builds the desired set of notifications from the DB, compares it with `pendingNotificationRequests()`, and cancels or schedules the difference. It's called on: app start, resume, login, sync completion, any change on the reminders watch stream (debounced 500 ms), and time zone change. Logout calls `cancelAll` for reminder ids.
5. **iOS limit of 64 pending notifications.** Reconcile schedules the nearest **50** reminders (leaving room for digests and snoozes). The rest get scheduled as earlier ones fire.
6. **Wall-clock times.** `remindAt` is a local wall-clock string (`2026-11-26T18:00:00`) chosen by the user. Schedule it with `tz.TZDateTime(tz.local, …)` built from its parts, never by adding `Duration`s (DST-safe). If the user travels, it fires at the same local clock time, like a calendar "floating" time.
7. **Background isolate DB access.** The action handler can run in a separate isolate while the main app is alive. Open Drift with `driftDatabase(name: 'notes_app', native: const DriftNativeOptions(shareAcrossIsolates: true))` in **both** isolates (change `AppDatabase()`), so writes don't fight over the SQLite file.

## Packages (check the newest stable versions on pub.dev when implementing)
- `flutter_local_notifications` (22.x at audit time; needs a recent Flutter SDK, AGP ≥ 8.11.1, compileSdk ≥ 35, core library desugaring)
- `timezone` (direct dependency; the plugin needs it for `zonedSchedule`)
- `flutter_timezone` (to read the device's IANA zone; the `timezone` package can't detect it)
- Optional: `app_settings` (to open the OS notification settings from a "Notifications are off" banner)

## Work item map
REM-01 infrastructure → REM-02 permissions → REM-03 scheduler → REM-07 backend → REM-04 actions → REM-05 repeats → REM-06 edit UI → REM-08 digests → REM-09 QA.
Prerequisites from the bug list: **FE-04** (stable ids) for REM-03, **FE-02** (offline outbox) for REM-04/06, **FE-03** (idempotency) for REM-07.
