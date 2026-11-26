# Daymark Implementation Status & Gap Analysis

## 1. Feature Status Matrix

| Module | Feature | Mobile Status | Backend API Status | Verification Method |
|---|---|---|---|---|
| **Auth & Session** | User Sign In | Complete | Available (`/auth/login`) | Integration Test |
| | User Registration | Complete | Available (`/auth/create-user`) | Integration Test |
| | Profile Details Display | Complete | Available (`/auth/user-details-by-userid`) | Integration Test |
| | Edit Profile (Name, Phone, Gender) | In Progress | Available (`/auth/update-user`) | Unit + Widget Test |
| | Change Password | In Progress | Available (`/auth/change-password`) | Integration Test |
| | Delete Account | In Progress | Available (`/auth/delete-user`) | Integration Test |
| | Log Out & Clear Session | Complete | Local + Session Reset | Unit Test |
| **Notes Management** | Notes List & Pull-to-Refresh | Complete | Available (`/notes/get-all-notes`) | Unit + Widget Test |
| | Create Note | Complete | Available (`/notes/create-note`) | Unit + Widget Test |
| | Edit Note | Complete | Available (`/notes/update-note`) | Unit + Widget Test |
| | Delete Note & Confirmation | Complete | Available (`/notes/delete-note`) | Unit + Widget Test |
| | Pinning / Unpinning | Complete | Available (`/notes/toggle-pin`) | Integration Test |
| | Note Tags Row & Input | Complete | Available (tags in `NotesModel`) | Integration Test |
| | Search & Category Filters | Complete | Available (Local + `/notes/search`) | Unit Test |
| **Calendar & Activity** | Month Navigation | Complete | Available (`/notes/calendar-summary`) | Widget Test |
| | Note Creation Counts by Date | Complete | Grouped by `createdAt` | Unit Test |
| | Horizontal Weekly Strip Sync | Complete | Shared State Selection | Widget Test |
| | Day Note Filtering | Complete | Available (`/notes/get-notes-by-date`) | Widget Test |
| **Settings & Preferences** | Light / Dark / System Theme | Complete | Local `themeModeProvider` | Unit Test |
| | Local Notifications / Reminders | Complete (device QA pending, REM-09) | NotificationService, ReminderScheduler, ReminderActionHandler, DigestScheduler (flutter_local_notifications) | Unit + Widget Tests |
| | JSON Backup / Export | In Progress | Available (`/notes/export` + Local) | Unit Test |
| | Help & FAQ | In Progress | In-App Help Modal | Visual / Unit Test |
| | About Daymark | In Progress | In-App About Modal | Visual / Unit Test |

## 2. Gaps Being Closed in Current Phase
1. **Frontend Backend Mapping**: Wire `tags` into `NoteItem`, `CachedNote`, `CreateNoteRequestDto`, and `UpdateNoteRequestDto`.
2. **Profile Actions**: Connect Edit Profile dialog, Change Password dialog, and Delete Account confirmation.
3. **Local Reminders**: Done (REM-01…REM-08): reminder notifications with Done / Not done / Snooze, Daily reminder and Weekly summary. Device QA in `work_items/REM-09-results.md`.
4. **JSON Backup / Export**: Implement formatted versioned JSON export with clipboard copy and file share.
5. **Calendar Integration**: Full binding between server-backed note dates and calendar activity indicators.
