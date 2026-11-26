# REM-03 — `ReminderScheduler`: schedule, reschedule and cancel from the DB

**Type:** Feature · **Priority:** P1 · **Area:** Frontend · **Depends on:** REM-01, FE-04 (stable local ids) · **Read:** REM-00

## Goal
The OS's scheduled notifications always match the reminders in Drift, whatever changed them: create, edit, delete, status change, sync, refresh, login or logout.

## Design
New file `lib/utils/services/reminder_scheduler.dart` (get_it singleton):

```dart
class ReminderScheduler {
  ReminderScheduler(this._db, this._notifications, this._session);
  Future<void> reconcile();          // idempotent, safe to call often
  Future<void> cancelAllReminders(); // used on logout
  void start();                      // subscribe to watchRemindersForUser (debounced 500 ms) + app resume
}
```

### `reconcile()` algorithm
1. If `!_notifications.isSupported` or `userId == 0` or permission isn't granted: return (cancel nothing; permission may come back).
2. Load the user's reminders from Drift, excluding tombstoned rows (FE-02).
3. Build the **desired** set: keep rows where `status == 'PENDING'` and the next fire time `> now`, where:
   - next fire time = `snoozedUntil` if set and in the future (add a nullable `snoozedUntil` text column to `CachedReminders`, schema bump together with FE-02's migration), otherwise
   - `parseWallClock(remindAt)` → `tz.TZDateTime(tz.local, y, m, d, h, min)`.
   - For repeating reminders whose `remindAt` is in the past, call REM-05's `nextOccurrence` first. If that changes `remindAt`, write it back through the repo (local first and queued) before scheduling.
4. Sort by fire time and take the first **50** (iOS cap of 64, minus digests and snoozes).
5. Each desired entry gets `id = row.id` (local id), title `row.title`, body such as `"Due 6:00 PM · Work"` (add `· Repeats daily` when repeating), and payload JSON `{"v":1,"type":"reminder","userId":…,"localId":row.id,"serverId":row.serverId,"occurrence":row.remindAt,"fireAt":"<iso>"}`.
6. Get `pending()` from the plugin. Only look at entries whose payload has `"type":"reminder"` (ignore digests in the 900000+ range).
   - Cancel pending ids that aren't desired, or whose payload `fireAt`/`occurrence`/title changed.
   - Schedule desired entries that are missing or were just cancelled.
7. Guard against two reconciles at once (a simple `_running` flag plus a "run again" flag, like `OfflineSyncService`).

### Triggers
- `start()` after login, or at startup when already logged in: subscribe to `db.watchRemindersForUser(userId)`, debounce 500 ms, then `reconcile()`.
- App resume (`AppLifecycleListener.onResume`): re-read the time zone (`FlutterTimezone`). If it changed, `tz.setLocalLocation(...)` and `reconcile()`.
- After `OfflineSyncService` finishes a sync or refresh: covered by the watch stream.
- After permission is granted (REM-02).
- `SessionService.logout()` (FE-01) calls `cancelAllReminders()` and stops the subscription.
- Android reboot: the plugin's `ScheduledNotificationBootReceiver` restores scheduled notifications. The next app open reconciles anyway.

### Helpers (pure functions, easy to unit test) in `lib/utils/reminder_time.dart`
- `DateTime? parseWallClock(String remindAt)`: accepts `yyyy-MM-ddTHH:mm[:ss]`, ignores any offset suffix.
- `tz.TZDateTime toTz(DateTime wallClock, tz.Location loc)`.
- `String formatDue(DateTime wallClock, {required bool use24h})`.

## Acceptance criteria
- [ ] Creating a reminder for 2 minutes ahead fires on time (app open, backgrounded and killed).
- [ ] Editing its time reschedules it, deleting it cancels it, and marking it completed in the app cancels it.
- [ ] Logging out cancels all reminder notifications. Logging back in reschedules them.
- [ ] With 80 future reminders, exactly 50 are pending. When the first fires and is handled, the 51st gets scheduled on the next reconcile.
- [ ] Unit tests with a fake `NotificationService` that records `schedule`/`cancel` calls: create, edit, delete, status change, snooze, cap of 50, time zone change, logout.
