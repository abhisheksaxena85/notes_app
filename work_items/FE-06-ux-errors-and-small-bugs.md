# FE-06 — Raw exceptions shown to users, stale note screen, delete without confirmation

**Type:** Bugs / UX polish · **Priority:** P2 · **Area:** Frontend · **Depends on:** none (pairs well with BE-03)

## Problems
1. **Raw exceptions in snackbars.** `note_details_viewmodel.dart:177,213` → `"An error occurred: $e"` shows `DioException [connection timeout]: …` text. `create_reminder_modal.dart` (~104) and `create_task_modal.dart` do the same.
2. **Note details provider is global and not auto-disposed** (`viewmodel/controllers.dart`, `noteDetailsController`). Opening note B after note A briefly shows A's title and content, because `loadNote` runs in a post-frame callback (`note_details_screen.dart:28-31`). The `TextEditingController`s created in the notifier are never disposed.
3. **No confirmation or undo on delete** for task and reminder cards (`home_screen.dart` `onDelete` → straight to the repo).
4. **Tasks and reminders can't be opened or edited.** Tapping a card does nothing, because `onTap` is not wired in `home_screen.dart` for `taskItemCard` / `reminderItemCard`. Editing reminders is covered in REM-06; tasks need the same (reuse `create_task_modal.dart` in edit mode).
5. `RetryInterceptor` (`data/network/interceptors/retry_interceptor.dart`) is a no-op: it passes every error through unchanged. Either implement a safe retry for idempotent GETs (1–2 retries on timeout or connection error, never for POST) or delete it.
6. Login: the loading state is replaced at once in `finally` (`login_viewmodel.dart:111-117`). It sets `AsyncError` and then overwrites it with `AsyncData`, so errors are never shown in the UI state.
7. Data & backup: export only copies to the clipboard (`build_profile_widget.dart` ~696). Large exports can exceed the clipboard limit on Android. Add "Save / Share file" (`share_plus` + `path_provider`).

## Proposed fix
- Add `lib/utils/res/api_error.dart` with `String userMessage(Object error)`: map `DioException` types (timeout, no connection, 401/403/404/409/5xx with the server `message`) to short, friendly text, and log the details. Use it in every catch that shows a snackbar.
- `noteDetailsController` → `AsyncNotifierProvider.autoDispose.family<…, int?>` keyed by `noteId`. Load in `build()`. Dispose controllers with `ref.onDispose`.
- Wrap deletes in a confirm dialog, or (better) delete optimistically with a 5-second "Undo" snackbar.
- Wire `onTap` for tasks to an edit modal.
- Fix the login state handling. Implement or delete `RetryInterceptor`.
- Add file export via the share sheet.

## Acceptance criteria
- [ ] No snackbar ever contains `Exception`, `DioException` or a stack-trace fragment.
- [ ] Opening two different notes in a row never flashes the previous one (widget test).
- [ ] Task and reminder delete can be undone. Tasks can be edited.
- [ ] Export can save or share a `.json`/`.csv` file.
