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
| **Calendar Activity Summary** | `GET` | `/notes/calendar-summary` | Query: `?userId={userId}&year={year}&month={month}` | `ApiResponse<CalendarSummaryResponseDto>` `{year, month, totalNotes, countsByDate}` | Permitted / Session | Aggregates note counts by creation date |
| **Notes By Date** | `GET` | `/notes/get-notes-by-date` | Query: `?userId={userId}&date={YYYY-MM-DD}` | `ApiResponse<List<NotesModel>>` | Permitted / Session | Fetches notes created on a specific calendar day |
| **Search Notes** | `GET` | `/notes/search` | Query: `?userId={userId}&query={query}` | `ApiResponse<List<NotesModel>>` | Permitted / Session | Full-text query on title, content, category, and tags |
| **Export Notes** | `GET` | `/notes/export` | Query: `?userId={userId}` | `ApiResponse<ExportNotesResponseDto>` `{exportVersion, exportedAt, totalNotes, notes}` | Permitted / Session | Generates versioned export payload for user notes |

## Data Model Conventions
- **Note IDs**: Numeric (`long` in Java, `int` in Dart).
- **User IDs**: Numeric (`long` in Java, `int` in Dart).
- **Date Formatting**: ISO-8601 string (`LocalDateTime.now().toString()`), e.g. `2026-11-18T02:10:00`.
- **Date Grouping**: Grouped strictly by original `createdAt` (never `updatedAt`).
- **Response Structure**: Unified envelope `ApiResponse<T>` with `boolean success`, `String message`, and `T data`.
