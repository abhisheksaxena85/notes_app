# BE-01 — Notes over 255 characters fail to save and block the whole sync queue

**Type:** Bug (data loss) · **Priority:** P0 · **Area:** Backend + Frontend sync · **Depends on:** none

## Problem
`Backend/src/main/java/com/example/notes_app/notes/model/NotesModel.java:15-19`:
```java
@Column(name = "title")   String title;
@Column(name = "content") String content;
```
With no `length` or `columnDefinition`, Hibernate creates `VARCHAR(255)` on MySQL. Any note body longer than 255 characters fails with `Data truncation: Data too long for column 'content'`. The spec (`docs/spec-workspace-tasks-reminders.md`, ER diagram) says `content` is `text`. The H2 tests don't catch this because the test notes are short.

### Knock-on effect in the app
Notes are created offline first and synced by `NoteRepo.syncQueuedNotes` (`Frontend/lib/data/repository/note/note_repo.dart:81-112`):
- The server answers `success:false` with HTTP 200, so the method **throws** `StateError`.
- It processes the queue in order and throws on the first failure. **Every note queued after the long one never syncs.**
- `OfflineSyncService.syncPendingAll` (`data/sync/offline_sync_service.dart:50-68`) wraps notes, tasks and reminders in **one** `try`. A throw from notes means **tasks and reminders never sync either**.
- The long note stays in the queue forever and is retried on every connectivity change.

## Proposed fix
Backend:
1. `@Column(name = "content", columnDefinition = "LONGTEXT")` (or `TEXT`, 64 KB) and `@Column(name = "title", length = 500)`.
2. `ddl-auto=update` **won't widen an existing column**. Add a one-off migration. The best option is Flyway (`spring-boot-starter-flyway` / `flyway-mysql`) with a baseline. The minimum is a documented SQL step:
   ```sql
   ALTER TABLE notes MODIFY content LONGTEXT;
   ALTER TABLE notes MODIFY title VARCHAR(500);
   ```
3. Add server validation (BE-03 / SEC-05) with a clear 400 for oversized input instead of a DB error.

Frontend (the queue-blocking part is handled properly in FE-03, but make sure this case is covered):
4. A permanent server rejection (4xx or `success:false`) must not block other items. Mark the item failed, surface it in the UI, and continue.

## Acceptance criteria
- [ ] Creating and updating a note with 10,000 characters of content works against MySQL.
- [ ] A backend test creates a note longer than 255 characters (also add `@Column` length assertions, or run the tests against MySQL with Testcontainers if feasible).
- [ ] Migration steps are written down in `Backend/HELP.md` or a Flyway script.
- [ ] Frontend test: a queue with [ok, rejected, ok] notes plus one task syncs the two good notes and the task.
