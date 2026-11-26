# BE-03 — Failures return HTTP 200 and raw exception text

**Type:** Bug / API quality · **Priority:** P1 · **Area:** Backend + Frontend · **Depends on:** none (don't combine with SEC-01 in one PR)

## Problem
- `AuthService` and `NotesService` catch every exception and return **HTTP 200** with `success:false` (for example `NotesService.java:53-56`, `69-72`, `101-104`). Tasks and reminders return proper 4xx/5xx, so the API is inconsistent.
- The message is `e.getMessage()`, so DB and driver errors (SQL text, constraint names) go straight to the client and are shown in snackbars.
- `common/GlobalExceptionHandler.java` maps **every** exception (including missing request params and malformed JSON, which should be 400) to **500** with `ex.getMessage()`.
- `deleteNote` defaults a missing id to `0` and then reports "Note does not exists!" (`NotesController.java:51-57`). Same for tasks and reminders.

## Proposed fix
1. Add small exception types: `NotFoundException` (404), `BadRequestException` (400), `ConflictException` (409), `UnauthorizedException` (401). Services throw them and stop catching broadly.
2. `GlobalExceptionHandler`:
   - Handle those types, plus `MethodArgumentNotValidException` / `HandlerMethodValidationException` (400 with field errors), `MissingServletRequestParameterException` / `HttpMessageNotReadableException` (400) and `DataIntegrityViolationException` (409).
   - Fallback: 500 with a generic `"Something went wrong"`. Log the real exception server-side.
3. Keep the `ApiResponse` envelope on errors so the client can still read `message`.
4. Make id params required (`@RequestParam long id`) instead of defaulting to 0.

## Frontend impact (must ship in the same release)
Dio's default `validateStatus` **throws** `DioException` for non-2xx. Code that currently does `if (response.success == false) showSnackBar(message)` will instead land in `catch`. Update the repos and viewmodels (`login_viewmodel.dart`, `register_viewmodel.dart`, `note_repo.dart`, `profile_repo.dart`, `task_repo.dart`, `reminder_repo.dart`) to read `e.response?.data['message']` from the `DioException`. Add a helper such as `ApiError.from(Object e)` (see FE-06).

## Acceptance criteria
- [ ] Not found → 404, bad input → 400, conflict → 409, unexpected → 500 with a generic message.
- [ ] No SQL or exception text in any response body (test a forced DB error).
- [ ] App still shows the right message for a wrong password, a duplicate email and a not-found note.
- [ ] Backend and frontend tests updated.
