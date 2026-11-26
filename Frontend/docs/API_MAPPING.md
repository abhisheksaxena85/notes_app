# Daymark API Mapping & Specification

This document maps all mobile client features directly to the authoritative Spring Boot backend REST endpoints, request/response structures, and authentication requirements.

## API Endpoint Matrix

| Mobile Feature | HTTP Method | Endpoint Path | Request DTO / Params | Response DTO / Payload | Auth / Security | Description |
|---|---|---|---|---|---|---|
| **User Sign In** | `POST` | `/auth/login` | `LoginRequestDto` `{email, password}` | `ApiResponse<LoginResponseDto>` `{userId}` | Public | Authenticates credentials and returns user ID |
| **User Registration** | `POST` | `/auth/create-user` | `SignupRequestDto` `{name, email, password, mobile, gender}` | `ApiResponse<SignupResponseDto>` `{userId}` | Public | Registers a new user account |
| **Get User Profile** | `GET` | `/auth/user-details-by-userid` | Query: `?id={userId}` | `ApiResponse<UserDetailsResponseDto>` `{id, name, email, mobile, gender}` | Permitted / Session | Fetches authenticated user's profile |
| **Update User Profile** | `PUT` | `/auth/update-user` | `UpdateUserRequestDto` `{userId, name, mobile, gender}` | `ApiResponse<UpdateUserResponseDto>` | Permitted / Session | Updates name, phone number, and gender |
| **Change Password** | `PUT` | `/auth/change-password` | `ChangePasswordRequestDto` `{userId, oldPassword, newPassword}` | `ApiResponse<Boolean>` | Permitted / Session | Validates old password and updates hash |
| **Delete User Account** | `DELETE` | `/auth/delete-user` | Query `?id={userId}` or Body | `ApiResponse<DeleteUserResponseDto>` | Permitted / Session | Deletes user account and cascades note deletion |
| **List User Notes** | `GET` | `/notes/get-all-notes` | Query: `?id={userId}` | `ApiResponse<List<NotesModel>>` | Permitted / Session | Fetches all notes owned by the authenticated user |
| **Get Note Details** | `GET` | `/notes/get-details-by-noteId` | Query: `?id={noteId}` | `ApiResponse<NotesModel>` | Permitted / Session | Fetches note details by ID |
| **Create Note** | `POST` | `/notes/create-note` | `CreateNoteRequestDto` `{userId, title, content, category, isPinned, tags}` | `ApiResponse<CreateNoteResponseDto>` `{noteId}` | Permitted / Session | Creates a new note with category, tags, and pin state |
| **Update Note** | `PUT` | `/notes/update-note` | `UpdateNoteRequestDto` `{noteId, title, content, category, isPinned, tags}` | `ApiResponse<UpdateNoteResponseDto>` | Permitted / Session | Updates title, content, category, tags, and pin state |
| **Toggle Note Pin** | `PUT` | `/notes/toggle-pin` | Query: `?id={noteId}` | `ApiResponse<NotesModel>` | Permitted / Session | Toggles note pin status directly |
| **Delete Note** | `DELETE` | `/notes/delete-note` | Query `?id={noteId}` or Body | `ApiResponse<NotesModel>` | Permitted / Session | Permanently deletes note for authenticated user |
| **Calendar Activity Summary** | `GET` | `/notes/calendar-summary` | Query: `?userId={userId}&year={year}&month={month}&tz={IANA zone, optional}` | `ApiResponse<CalendarSummaryResponseDto>` `{year, month, totalNotes, countsByDate}` | Permitted / Session | Aggregates counts per day; timestamps bucketed in `tz` (UTC when absent) |
| **Notes By Date** | `GET` | `/notes/get-notes-by-date` | Query: `?userId={userId}&date={YYYY-MM-DD}&tz={IANA zone, optional}` | `ApiResponse<List<NotesModel>>` | Permitted / Session | Fetches notes created on a calendar day in `tz` (UTC when absent) |
| **Day Activity** | `GET` | `/notes/day-activity` | Query: `?userId={userId}&date={YYYY-MM-DD}&tz={IANA zone, optional}` | `ApiResponse<DayActivityResponseDto>` `{date, totalCount, notes, tasks, reminders}` | Permitted / Session | Everything on one day, bucketed like the calendar summary |
| **Search Notes** | `GET` | `/notes/search` | Query: `?userId={userId}&query={query}` | `ApiResponse<List<NotesModel>>` | Permitted / Session | Full-text query on title, content, category, and tags |
| **Export Notes** | `GET` | `/notes/export` | Query: `?userId={userId}` | `ApiResponse<ExportNotesResponseDto>` `{exportVersion, exportedAt, totalNotes, notes}` | Permitted / Session | Generates versioned export payload for user notes |
| **Create Task** | `POST` | `/tasks/create-task` | `CreateTaskRequestDto` `{userId, title, description, dueDate, dueTime, category, priority, status, isCompleted, clientId}` | `ApiResponse<CreateTaskResponseDto>` `{taskId}` | Permitted / Session | 201 on insert; 200 with the existing id when `clientId` was already used by this user |
| **List Tasks** | `GET` | `/tasks/get-all-tasks` | Query: `?userId={userId}` | `ApiResponse<List<TaskModel>>` | Permitted / Session | Not completed first, then by due date |
| **Tasks By Date** | `GET` | `/tasks/get-tasks-by-date` | Query: `?userId={userId}&date={YYYY-MM-DD}` | `ApiResponse<List<TaskModel>>` | Permitted / Session | Tasks whose `dueDate` is that day |
| **Get Task Details** | `GET` | `/tasks/get-task-details` | Query: `?id={taskId}` | `ApiResponse<TaskModel>` | Permitted / Session | One task |
| **Update Task** | `PUT` | `/tasks/update-task` | `UpdateTaskRequestDto` `{taskId, title?, description?, dueDate?, dueTime?, category?, priority?, status?, isCompleted}` | `ApiResponse<TaskModel>` | Permitted / Session | Partial update; `isCompleted` always follows `status` |
| **Set Task Status** | `PUT` | `/tasks/toggle-status` | Query: `?taskId={id}&status={status, optional}` | `ApiResponse<TaskModel>` | Permitted / Session | Sets `status`; without it, toggles COMPLETED ↔ PENDING |
| **Delete Task** | `DELETE` | `/tasks/delete-task` | Query: `?taskId={id}` (or `?id=`) | `ApiResponse<Boolean>` | Permitted / Session | 404 if it doesn't exist |
| **Create Reminder** | `POST` | `/reminders/create-reminder` | `CreateReminderRequestDto` `{userId, title, remindAt, dueDate?, dueTime?, category?, status?, repeatInterval?, startAt?, clientId?}` | `ApiResponse<CreateReminderResponseDto>` `{reminderId}` | Permitted / Session | `startAt` defaults to `remindAt`; `dueDate`/`dueTime` derived from `remindAt` when absent; idempotent by `clientId` like tasks |
| **List Reminders** | `GET` | `/reminders/get-all-reminders` | Query: `?userId={userId}` | `ApiResponse<List<ReminderModel>>` | Permitted / Session | PENDING, then MISSED, COMPLETED, REJECTED; earliest `remindAt` first within each |
| **Reminders By Date** | `GET` | `/reminders/get-by-date` | Query: `?userId={userId}&date={YYYY-MM-DD}` | `ApiResponse<List<ReminderModel>>` | Permitted / Session | Reminders whose `dueDate` is that day |
| **Update Reminder** | `PUT` | `/reminders/update-reminder` | `UpdateReminderRequestDto` `{reminderId, title?, remindAt?, dueDate?, dueTime?, category?, status?, repeatInterval?, startAt?, lastOutcome?, lastOutcomeAt?}` | `ApiResponse<ReminderModel>` | Permitted / Session | Partial update. A new `remindAt` re-derives `dueDate`/`dueTime` unless they are sent, and becomes the new `startAt` unless `startAt` is sent |
| **Set Reminder Status** | `PUT` | `/reminders/update-status` | Query: `?reminderId={id}&status={status, optional}` | `ApiResponse<ReminderModel>` | Permitted / Session | Sets `status`; without it, toggles COMPLETED ↔ PENDING |
| **Answer Reminder Occurrence** | `PUT` | `/reminders/complete-occurrence` | `CompleteOccurrenceRequestDto` `{reminderId, occurrence, outcome: COMPLETED\|MISSED}` | `ApiResponse<ReminderModel>` | Permitted / Session | One-off: `status = outcome`. Repeating: if `occurrence == remindAt`, moves `remindAt` to the next occurrence (anchored to `startAt`), keeps PENDING and sets `lastOutcome`/`lastOutcomeAt`; otherwise returns the reminder unchanged (idempotent) |
| **Delete Reminder** | `DELETE` | `/reminders/delete-reminder` | Query: `?reminderId={id}` (or `?id=`) | `ApiResponse<Boolean>` | Permitted / Session | 404 if it doesn't exist |

## Data Model Conventions
- **Note IDs**: Numeric (`long` in Java, `int` in Dart).
- **User IDs**: Numeric (`long` in Java, `int` in Dart).
- **Timestamps (`createdAt`, `updatedAt`, `exportedAt`)**: absolute instants, ISO-8601 in UTC, e.g. `2026-11-25T20:00:00.123Z` (server: `Timestamps.now()`; app: `DateKeys.nowUtc()`). Values without an offset were written before BE-02 by a server running in UTC; they are read as UTC and never rewritten.
- **Wall-clock values (task `dueDate`/`dueTime`, reminder `remindAt`/`dueDate`/`dueTime`)**: the date and time the user picked, with no zone. They are stored and shown as is and never converted, so "9:00 on Nov 26" stays 9:00 on Nov 26 wherever the user is.
- **Date Grouping**: notes by `createdAt` (never `updatedAt`), converted to the viewer's zone first: the app uses `DateKeys.localDay`, the server uses the `tz` query parameter (an IANA name such as `Asia/Kolkata`; UTC when absent; an unknown name is a 400). Tasks go on their `dueDate`, or on the local day of `createdAt` when they have none; reminders on their `dueDate`, else the date part of `remindAt`.
- **Enumerations** (case-insensitive on input, upper case on output; anything else is a 400): `status` PENDING / COMPLETED / REJECTED / MISSED; `repeatInterval` NONE / DAILY / WEEKLY / MONTHLY; `priority` LOW / MEDIUM / HIGH; reminder `lastOutcome` / occurrence `outcome` COMPLETED / MISSED.
- **Wall-clock formats** (a 400 otherwise): `remindAt`, `startAt`, `occurrence`, `lastOutcomeAt` are `yyyy-MM-ddTHH:mm[:ss]` and are returned as `yyyy-MM-ddTHH:mm:ss`; `dueDate` is `yyyy-MM-dd`; `dueTime` is `HH:mm`.
- **Repeating reminders**: `startAt` is the first occurrence and the anchor of the series; `remindAt` is always the next pending occurrence. Monthly repeats keep `startAt`'s day of month, clamped to shorter months (Jan 31 → Feb 28 → Mar 31).
- **Response Structure**: Unified envelope `ApiResponse<T>` with `boolean success`, `String message`, and `T data`.
