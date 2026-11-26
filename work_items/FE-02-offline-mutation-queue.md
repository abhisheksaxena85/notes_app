# FE-02 — Offline edits, status changes and deletes are lost or come back

**Type:** Bug (data loss) · **Priority:** P0 · **Area:** Frontend data layer · **Depends on:** FE-03 (single sync entry point), works best with FE-04

## Problem
Only **creates** are queued offline. Everything else is either online-only or fire-and-forget, and the next server refresh overwrites local changes.

Evidence:
- **Tasks and reminders, status change and delete:** `TaskRepo.setTaskStatus` / `deleteTask` (`data/repository/task/task_repo.dart` ~129-180) and `ReminderRepo.updateReminderStatus` / `deleteReminder` (`data/repository/reminder/reminder_repo.dart:121-176`) update Drift, then call the API inside `try { } catch (_) { /* Ignored for offline tolerance */ }`. If the call fails, nothing retries it.
- Then `fetchAndCacheTasks` / `fetchAndCacheReminders` call `replaceServerTasks` / `replaceServerReminders` (`data/local/database/app_database.dart` ~435-447, 611-623). These **delete all non-pending rows and re-insert the server list**. So:
  - an offline status change **reverts** to the server value;
  - an offline delete **comes back** on the next refresh.
- **Edits:** `TaskRepo.updateTask` and `ReminderRepo.updateReminder` only talk to the server. For an unsynced item (negative id) they **do nothing at all**. Offline, they throw.
- **Notes:** `NoteRepo.updateNote`, `togglePin` and `deleteNote` (`note_repo.dart:115-197`) are online-only. For an **unsynced local note** (negative id), `NoteDetailsViewmodel.saveOrUpdateNote` / `deleteNote` call the API with a negative id, and the server answers "Note does not exists!". **Unsynced notes can't be edited or deleted**, even online.

This also blocks the reminder feature: tapping **Done** on a notification (REM-04) often happens offline or with the app killed, so the change has to be stored locally and replayed reliably.

## Proposed fix: a generic outbox
1. **Schema (Drift `schemaVersion` 3):** add a table `PendingMutations`:
   `id` (auto), `userId`, `entity` (`note|task|reminder`), `op` (`create|update|status|delete`), `localId` (int, nullable), `serverId` (int, nullable), `clientId` (TEXT UUID, see FE-03), `payload` (JSON), `attempts` (int), `lastError` (text), `queuedAt`.
   Migrate the existing `PendingNotes/PendingTasks/PendingReminders` rows into it as `create` ops (or keep those tables for creates and use the new table for update/status/delete only; pick one and document it).
2. **Tombstones:** add `isDeleted` (bool) to `CachedNotes/CachedTasks/CachedReminders`, or a `deletedServerIds` table. A delete sets the tombstone and queues `delete`. Watch queries filter out tombstoned rows. The tombstone is removed when the server confirms.
3. **Local first, always:** every repo write (create, update, status, pin, delete) does one Drift transaction: apply the change to the cached row, set `isPending=true` (or `dirty=true`), append a mutation. Then call `OfflineSyncService.requestSync()`. No direct API calls from repos for writes.
4. **Coalescing:** for an item that is still `create`-pending (negative id), patch the queued create payload instead of adding a new op (the code already does this for status, `task_repo.dart:136-146`; extend it to all fields and to notes). Delete of a create-pending item removes both the row and its create (already done for tasks and reminders; add it for notes).
5. **Replay** (`OfflineSyncService`): process mutations in `id` order per entity. Map `localId` → `serverId` after a create completes, so a later `update`/`status`/`delete` for the same item uses the new server id. On 404 for update or delete, drop the op (the item is gone on the server). Transient errors (timeouts, 5xx, no network): stop, back off, retry later. Permanent 4xx: mark `lastError`, skip, and show it in the UI.
6. **Merge rule for refresh:** `replaceServer*` must **not** overwrite rows that have a pending mutation, and must not resurrect tombstoned server ids. Implement it as upsert by `serverId` (FE-04) plus "delete rows missing from the server list only if they're not dirty".
7. Notes: `NoteDetailsViewmodel` edit and delete go through the repo's local-first path, which removes the negative-id API calls.

## Acceptance criteria
- [ ] Offline: complete a synced task, delete a synced reminder, edit a synced note, edit an **unsynced** note, delete an unsynced note. All show at once and survive an app restart.
- [ ] Back online: all changes reach the server in order, and a refresh doesn't undo or resurrect anything.
- [ ] Create offline, then edit, then complete, then sync: the server gets one create with the final values (or a create followed by updates, but the end state is correct).
- [ ] Unit tests with `AppDatabase.forTesting(NativeDatabase.memory())` and a fake `ApiClient` cover each scenario, including a failure midway.
- [ ] Drift migration test from schema 2 → 3 (`drift_dev` schema dump plus a migration test).
