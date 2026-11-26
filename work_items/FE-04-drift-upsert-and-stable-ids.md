# FE-04 — Drift upserts break the unique key; cache refresh changes local ids

**Type:** Bug · **Priority:** P1 · **Area:** Frontend local DB · **Depends on:** none

## Problems
1. **Notes upsert targets the wrong key.** `AppDatabase.saveServerNote` (`data/local/database/app_database.dart:306-308`) uses `into(cachedNotes).insertOnConflictUpdate(note)`. The companion comes from `NoteDatabaseMapper.fromDetails` / `fromNoteItem`, which sets no local `id`, so the conflict target is the primary key and never matches. When the note is already cached, the insert breaks the **unique `(userId, serverId)`** key (`CachedNotes.uniqueKeys`) and throws `SqliteException: UNIQUE constraint failed`.
   It's called after a successful server update in `NoteRepo.updateNote`, `togglePin` and `getNoteDetails` (`note_repo.dart:127,157,183`) and during import. **The server change goes through, but the app reports an error and the local copy isn't updated.**
   The same author already fixed this for tasks and reminders (`saveServerTask` / `saveServerReminder` at ~450-466 and ~626-640, with a comment explaining it), but not for notes.
   *First step: write a failing test (cache a note, then call `saveServerNote` with the same serverId) to confirm.*
2. **`replaceServer*` changes local ids on every refresh.** `replaceServerNotes` / `replaceServerTasks` / `replaceServerReminders` delete every non-pending row and re-insert (~201-214, 435-447, 611-623), so every refresh gives each row a new autoincrement `id`. Problems:
   - Any feature that keys on the local row id breaks. **The reminder notifications in REM-03 need a stable id per reminder** (the notification id).
   - Watch streams emit a full delete-then-insert, so lists flicker and lose scroll position.
   - It works against FE-02's rule that dirty rows must survive a refresh.
3. `CachedProfiles` upsert is fine (its primary key is `userId`).

## Proposed fix
1. Add one generic helper in `AppDatabase`, `_upsertByServerId(table, companion)`: update where `userId & serverId` match, otherwise insert. Use it for notes, tasks and reminders. Delete the duplicated code.
2. Rewrite `replaceServer*` as a **merge**, in one transaction:
   - upsert each server item by `(userId, serverId)` and keep its local `id`;
   - delete local rows with a `serverId` that's **not** in the server list **and** have no pending mutation or tombstone (FE-02);
   - never touch rows where `serverId IS NULL` (local-only, pending create).
3. Optional: skip the write when nothing changed, to avoid stream churn.

## Acceptance criteria
- [ ] Test: `saveServerNote` twice with the same serverId leaves one row with the updated fields and no exception.
- [ ] Test: two consecutive `replaceServerReminders` calls with the same list keep the same local `id`s.
- [ ] Test: a server item removed from the list is deleted locally, unless it has a pending mutation.
- [ ] Existing tests (`local_database_test.dart`, `note_sync_test.dart`, `task_reminder_offline_test.dart`) still pass.
