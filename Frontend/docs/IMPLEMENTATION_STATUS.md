# Daymark Implementation Status & Gap Analysis

Checked against the code on 2026-11-27. "Local" means the app works from its Drift cache and syncs in the background (offline first); endpoints are listed in [API_MAPPING.md](API_MAPPING.md).

## 1. Feature Status Matrix

| Module | Feature | Mobile Status | Backend / Data Source | Verification |
|---|---|---|---|---|
| **Auth & Session** | Sign in | Complete | `/auth/login` → access token | `auth_token_test.dart`, `ux_errors_undo_edit_test.dart` |
| | Registration | Complete | `/auth/create-user` → access token | `auth_token_test.dart`, `password_rules_test.dart` |
| | Access token (JWT) | Complete | Stored in the platform keystore (`TokenStore`), sent as `Authorization: Bearer` by `AuthInterceptor`; a 401 signs out once and keeps unsynced changes | `auth_token_test.dart` |
| | Session / account switch | Complete | `SessionService` is the single source of truth; logout wipes the user's local data | `session_switch_test.dart` |
| | Profile details | Complete | `/auth/user-details-by-userid`, cached locally | `session_switch_test.dart` |
| | Edit profile (name, phone, gender) | Complete | `/auth/update-user` (Profile → Account → Edit) | Backend `NotesApiTests`, `EntityAndServiceFixesTests` |
| | Change password | **Not in UI** | `/auth/change-password` exists; `ProfileRepo.changePassword` exists, no screen calls it | Backend `AuthHardeningTests` |
| | Delete account | Complete | `/auth/delete-user` with confirmation, then local sign-out | Backend `OwnershipTests` |
| | Log out | Complete | Local: token, data and scheduled notifications cleared | `session_switch_test.dart` |
| **Notes** | List, pull to refresh | Complete | Local + `/notes/get-all-notes` (pinned first, newest first) | `note_sync_test.dart`, `server_merge_test.dart` |
| | Create / edit / delete (with confirmation) | Complete | Local first, outbox to `/notes/create-note`, `/notes/update-note`, `/notes/delete-note` | `offline_mutations_test.dart`, `sync_service_test.dart` |
| | Note screen per note | Complete | Provider keyed by note id, disposed on close | `ux_errors_undo_edit_test.dart` |
| | Pin / unpin | Complete | Saved with the note | `offline_mutations_test.dart` |
| | Tags | Complete | `tags` on the note | `daymark_design_test.dart` |
| | Search & category filter | Complete | Local (home screen); `/notes/search` exists but is not used | Widget tests |
| | Export one note | Complete | Local, copy as CSV / TXT / JSON | `note_export_import_test.dart` |
| **Tasks** | Create | Complete | Local first, `/tasks/create-task` with `clientId` (idempotent) | `task_reminder_offline_test.dart` |
| | Edit (tap a task) | Complete | Task modal in edit mode; only changed fields, `/tasks/update-task` | `ux_errors_undo_edit_test.dart` |
| | Status (done / pending / rejected / missed) | Complete | `/tasks/toggle-status`; overdue PENDING shows as MISSED | `tasks_reminders_calendar_test.dart` |
| | Delete with Undo | Complete | 5 s Undo snackbar, then `/tasks/delete-task` | `ux_errors_undo_edit_test.dart` |
| **Reminders** | Create (no past times) | Complete | Local first, `/reminders/create-reminder` | `reminder_form_test.dart` |
| | Edit (tap a reminder) | Complete | `/reminders/update-reminder`; delete from the form asks first | `reminder_form_test.dart` |
| | Repeating (daily / weekly / monthly) | Complete | Next occurrence via `/reminders/complete-occurrence` | `repeating_reminders_test.dart` |
| | Delete with Undo (card) | Complete | 5 s Undo snackbar, then `/reminders/delete-reminder` | `ux_errors_undo_edit_test.dart` |
| **Notifications** | Reminder notifications | Complete (device QA pending, REM-09) | Local only (`flutter_local_notifications`): `NotificationService`, `ReminderScheduler` (nearest 50) | `notification_service_test.dart`, `reminder_scheduler_test.dart` |
| | Done / Not done / Snooze actions | Complete | `ReminderActionHandler`, also with the app killed (background isolate) | `reminder_action_handler_test.dart` |
| | Permissions (notifications, exact alarms) | Complete | `NotificationPermissionService`; banner when upcoming reminders can't alert | `notification_permission_test.dart` |
| | Daily reminder / Weekly summary | Complete | `DigestScheduler` (Profile → Notifications) | `digest_scheduler_test.dart` |
| **Calendar** | Month view with counts, week strip, day list | Complete | Local (notes by `createdAt` day, tasks/reminders by due date); `/notes/calendar-summary`, `/notes/get-notes-by-date` and `/notes/day-activity` exist but are not used | `tasks_reminders_calendar_test.dart`, `date_keys_test.dart` |
| **Sync** | Offline queue, retries, failures banner | Complete | `OfflineSyncService`, outbox, `SyncFailuresBanner` (retry / discard) | `sync_service_test.dart`, `sync_failures_banner_test.dart` |
| | Friendly error messages | Complete | `userMessage()` (`utils/res/api_error.dart`) in every snackbar and error view | `api_error_test.dart`, `ux_errors_undo_edit_test.dart` |
| **Settings & Data** | Light / Dark / System theme | Complete | Local | `daymark_design_test.dart` |
| | Export all notes | Complete | Local; "Save / Share file" (`.csv` / `.txt` / `.json` via the share sheet) or copy to clipboard. `/notes/export` exists but is not used | `ux_errors_undo_edit_test.dart`, `note_export_import_test.dart` |
| | Import notes | Complete | Paste CSV / TXT / JSON; duplicates skipped, new notes queued for sync | `note_export_import_test.dart` |
| | Help & FAQ, About, Privacy | Complete | In-app sheets / dialogs (static text) | Manual |

## 2. Known Gaps
1. **Change password** has no screen yet (backend endpoint and repository method are ready).
2. **Device QA** for notifications on real phones (REM-09) is not signed off; see `work_items/REM-09-results.md`.
3. **Server-side calendar, search and export** endpoints are kept for other clients; the app computes these from its local cache.
4. **Release signing** needs the owner's upload key in `android/key.properties` (see the README). Without it, release builds use the debug key.
