# REM-04 — Done / Not done / Snooze actions, including when the app is killed

**Type:** Feature · **Priority:** P1 · **Area:** Frontend · **Depends on:** REM-03, FE-02 (local-first outbox), FE-04 · **Read:** REM-00

## Goal
The user's answer from the notification is saved reliably and reflected in the app and on the server, whatever state the app is in.

## Entry points (all route to one handler)
| App state | Callback |
|---|---|
| Foreground or background, running | `onDidReceiveNotificationResponse` (set in `NotificationService.init`) |
| Killed, action button with `showsUserInterface:false` (Android) / non-foreground action (iOS) | `@pragma('vm:entry-point') notificationTapBackground` (background isolate) |
| Killed, user tapped the **body** | app launches; `NotificationService.launchDetails()` in `initialize()` → `didNotificationLaunchApp` + `notificationResponse` |

## `ReminderActionHandler` (new, `lib/utils/services/reminder_action_handler.dart`)
```dart
class ReminderActionHandler {
  Future<void> handle(NotificationResponse r);
}
```
Steps:
1. Parse the payload. Ignore anything without `"type":"reminder"` or with the wrong `v`.
2. Load the reminder by `localId`. If it's missing, look it up by `serverId` (it may have been re-cached). If it's still missing, return (it was deleted).
3. **Idempotency:** if `row.remindAt != payload.occurrence` and the action isn't a snooze of that same occurrence, return. The tap was already handled, or the reminder was edited.
4. Map `r.actionId`:
   - `reminder_done`: one-off → `repo.updateReminderStatus(id, 'COMPLETED')`; repeating → `repo.completeOccurrence(id, occurrence, 'COMPLETED')` (REM-05 advances `remindAt`, keeps `PENDING`).
   - `reminder_not_done`: one-off → `'MISSED'`; repeating → `completeOccurrence(..., 'MISSED')`.
   - `reminder_snooze`: set `snoozedUntil = now + 10 min` locally (no server call needed). Make the duration a constant.
   - `null` (body tapped): don't change status. In the main isolate, navigate to the Workspace tab with the reminder highlighted and open a bottom sheet: **"Did you complete '<title>'?"** [Done] [Not done] [Snooze 10 min]. The buttons call this same handler with the matching action id.
5. All writes go through the local-first repo path from FE-02 (Drift transaction plus outbox entry). Clear `snoozedUntil` on done or not done.
6. Call `ReminderScheduler.reconcile()` so the next occurrence or the snooze gets scheduled and stale ones are cancelled.
7. Try `OfflineSyncService.requestSync()` with a short timeout (don't block). If it fails, the main app syncs later.

## Background isolate specifics (`notificationTapBackground`)
- First line: `WidgetsFlutterBinding.ensureInitialized(); DartPluginRegistrant.ensureInitialized();`
- Build a **minimal** dependency graph. **Don't** call the full `configureDependencies()` if it starts the connectivity listener or sync loops. Create `Preference.init()`, `AppDatabase()` (with `shareAcrossIsolates: true`, see REM-00), `ReminderRepo` and `ApiClient` (with the auth token from secure storage, SEC-02), then `ReminderActionHandler`.
- Initialise `timezone` (same as `NotificationService.init`) so reconcile computes correct times. The plugin must be initialised in this isolate before calling `zonedSchedule`.
- Wrap everything in try/catch and log. A crash here loses the tap silently.
- Close the DB at the end (`await db.close()`) unless the isolate is reused.
- Note: if the main isolate is alive, its Drift watch stream will see the change when the DB is shared across isolates. Check this in a test or manually. If it doesn't, the main isolate should call `refresh`/reconcile on resume.

## Foreground behaviour
- If a reminder fires while the app is open: on Android it still shows as a heads-up notification. On iOS set `presentAlert/presentBanner/presentSound: true` in `DarwinNotificationDetails` so it shows in the foreground too.
- After handling an action while the app is open, show a snackbar: "Marked done ✓" with **Undo** (sets the status back to `PENDING` and restores `remindAt` for repeats).

## Acceptance criteria
- [ ] Android 14, app killed: reminder fires → tap **Done** → open the app: the card shows completed (green and struck through) without any manual refresh. With network on, the server shows `COMPLETED` within a few seconds; offline, after reconnecting.
- [ ] Same for **Not done** → red/missed, and **Snooze** → fires again 10 minutes later.
- [ ] Tapping the body opens the app on the reminder sheet (cold start and warm start).
- [ ] Tapping Done twice (two devices, or a duplicated callback) applies once.
- [ ] iOS: the same scenarios (background, and killed where iOS allows).
- [ ] Unit tests for `ReminderActionHandler` using an in-memory DB and fakes: each action, the idempotency check, the deleted-reminder case, and repeat advance calling REM-05.
