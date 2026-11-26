# FE-03 — Sync races create duplicates; one failing item blocks all syncing

**Type:** Bug (duplicates, stuck queue) · **Priority:** P0 · **Area:** Frontend sync + small backend change · **Depends on:** none

## Problems
1. **Two sync paths running at once.** `TaskViewmodel.createTask` calls `unawaited(_taskRepo.syncQueuedTasks(userId))` (`viewmodel/task/task_viewmodel.dart:79`), and `ReminderViewmodel.createReminder` calls `unawaited(_reminderRepo.syncQueuedReminders(userId))` (`viewmodel/reminder/reminder_viewmodel.dart:79`). `NoteRepo.importNotes` calls `syncQueuedNotes` directly (`note_repo.dart:~346`). These skip the `_isSyncing` guard in `OfflineSyncService`. If a connectivity event (or app start) triggers `syncPendingAll()` at the same moment, both loops read the same pending row and **POST it twice**, creating a duplicate on the server.
2. **No idempotency.** If a create POST succeeds on the server but the response is lost (timeout on a bad network), the row stays queued and is created again next time. Neither side has a way to de-duplicate.
3. **One failure stops everything.**
   - `NoteRepo.syncQueuedNotes` throws on the first non-2xx or `success:false` (see BE-01), so no later notes sync.
   - `TaskRepo.syncQueuedTasks` / `ReminderRepo.syncQueuedReminders` `continue` on non-2xx (a permanently bad item is retried forever) but `break` on exceptions.
   - `OfflineSyncService.syncPendingAll` (`data/sync/offline_sync_service.dart:50-68`) uses one `try` for all three. A notes failure skips tasks and reminders.
4. No backoff: every connectivity flap triggers a full retry.

## Proposed fix
1. **One entry point:** make `OfflineSyncService.requestSync()` the only way to sync. Make `syncQueued*` private, or only callable from the service. Viewmodels and repos call `getIt<OfflineSyncService>().requestSync()`.
2. **Idempotency key:**
   - Frontend: generate a UUID `clientId` (add the `uuid` package) when an item is queued. Store it on the cached row and in the payload.
   - Backend: add a nullable `client_id VARCHAR(36)` column with a unique index `(user_id, client_id)` to notes, tasks and reminders, and accept `clientId` in the create DTOs. If the row already exists for that user and clientId, **return the existing id with 200** instead of inserting.
3. **Isolation:** sync each entity type in its own try/catch. Per item, classify errors:
   - transient (no response, timeout, 5xx): stop this entity's loop, schedule a retry with exponential backoff (for example 5 s → 5 min).
   - permanent (4xx except 408/429, or `success:false` with a 2xx): mark the item failed (`attempts`, `lastError`), **skip it and continue**, and surface "1 item couldn't sync" in the UI with retry and discard options.
4. Also trigger sync on app resume (`AppLifecycleListener`), not only on connectivity change.

## Acceptance criteria
- [ ] Calling `requestSync()` 5 times concurrently with one queued item gives exactly one POST (test with a fake client that counts calls).
- [ ] Fake client creates the item but throws on the response, then the next sync runs: the server ends up with one row (backend idempotency test with the same `clientId`).
- [ ] Queue [bad note, good note, good task, good reminder]: the three good ones sync and the bad one is marked failed.
- [ ] Backend migration adds `client_id` columns. Old clients that send no `clientId` still work.
