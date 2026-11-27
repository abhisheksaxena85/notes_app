# Daymark — Work Items

Audit date: 2026-11-26. Scope: `Backend/` (Spring Boot 4.1, MySQL, JPA) and `Frontend/` (Flutter, Riverpod, Drift, Dio).

Each file in this folder is one self-contained work item, written so Claude Code can pick it up and finish it on its own. Each one has the evidence (file and line), the impact, a proposed fix, acceptance criteria and the tests to add.

## How to run an item in Claude Code

From the repo root:

```
claude "Read work_items/README.md and work_items/FE-02-offline-mutation-queue.md. Implement that work item. Follow its acceptance criteria, add the tests it lists, and run the verification commands. Do not start other work items."
```

Rules for every item:
- Do one item per branch/PR, named after the ID (`fix/FE-02-offline-mutation-queue`).
- Check the item's **Depends on** list first. If a dependency isn't merged, stop and say so.
- Line numbers are from the audit snapshot and may drift. Search for the quoted code if a line doesn't match.
- When an item is done, tick it in the table below.

### Verification commands
| Area | Command |
|---|---|
| Backend | `cd Backend && ./mvnw test` |
| Frontend codegen (after Drift/json changes) | `cd Frontend && dart run build_runner build --delete-conflicting-outputs` |
| Frontend | `cd Frontend && flutter analyze && flutter test` |

### Project conventions (for the agent)
- Backend: every endpoint returns `ApiResponse<T>` (`success`, `message`, `data`). Packages are split by feature: `auth`, `notes`, `tasks`, `reminders`, each with `controller/service/repository/model/dto`.
- Frontend: MVVM. `views/` → `viewmodel/` (Riverpod `AsyncNotifier`, registered in `viewmodel/controllers.dart`) → `data/repository/` → `data/network` (Dio `ApiClient`) and `data/local/database` (Drift `AppDatabase`). Dependency injection uses get_it (`data/di/dependency_injection.dart`).
- Offline first: creates go into `Pending*` tables and `OfflineSyncService` replays them. Local-only rows are exposed with a **negative** id (`-localRowId`). Synced rows use the server id.
- Design tokens come from `context.daymark` (`DaymarkPalette`, `utils/constants/app_colors.dart`).

## Index

Priority: **P0** = security hole or data loss, fix first · **P1** = broken behaviour users will hit · **P2** = quality, hygiene, polish.

### Security
| ✓ | ID | Title | Priority | Depends on |
|---|---|---|---|---|
| ☑ | [SEC-01](SEC-01-backend-jwt-auth-and-ownership.md) | Backend: real authentication (JWT) and per-user ownership checks | P0 | — |
| ☐ | [SEC-02](SEC-02-frontend-token-auth.md) | Frontend: send and store the auth token, handle 401 | P0 | SEC-01 |
| ☑ | [SEC-03](SEC-03-leaked-db-password.md) | DB password committed to git: rotate it and move secrets to env | P0 | — |
| ☑ | [SEC-04](SEC-04-passwords-in-logs.md) | Passwords and request bodies written to logs (also in release builds) | P0 | — |
| ☑ | [SEC-05](SEC-05-auth-hardening.md) | Auth hardening: account enumeration, email uniqueness, input validation | P1 | — |

### Backend
| ✓ | ID | Title | Priority | Depends on |
|---|---|---|---|---|
| ☑ | [BE-01](BE-01-note-content-255-limit.md) | Notes over 255 characters fail to save and block the whole sync queue | P0 | — |
| ☑ | [BE-02](BE-02-server-timezone-dates.md) | Server timestamps use server-local time, so items land on the wrong calendar day | P1 | — |
| ☑ | [BE-03](BE-03-http-status-and-errors.md) | Failures return HTTP 200 and raw exception text | P1 | — |
| ☑ | [BE-04](BE-04-reminder-service-bugs.md) | Reminder service: completed sort first, stale dueDate after edit, no validation | P1 | — |
| ☐ | [BE-05](BE-05-entity-lombok-and-misc.md) | `@Data` on JPA entities plus small service bugs | P2 | — |
| ☑ | [BE-06](BE-06-docker-port-and-ci.md) | CI workflow can't find the Dockerfile; container port mismatch; no tests in CI | P1 | — |
| ☐ | [BE-07](BE-07-springdoc-boot4-compat.md) | Check springdoc 2.x works with Spring Boot 4 | P2 | — |

### Frontend
| ✓ | ID | Title | Priority | Depends on |
|---|---|---|---|---|
| ☑ | [FE-01](FE-01-session-logout-account-switch.md) | Logging out and in as another user shows the previous user's data | P0 | — |
| ☑ | [FE-02](FE-02-offline-mutation-queue.md) | Offline edits, status changes and deletes are lost or come back | P0 | FE-03 |
| ☑ | [FE-03](FE-03-sync-races-and-idempotency.md) | Sync races create duplicates; one failing item blocks all syncing | P0 | — |
| ☑ | [FE-04](FE-04-drift-upsert-and-stable-ids.md) | Drift upserts break the unique key; cache refresh changes local ids | P1 | — |
| ☑ | [FE-05](FE-05-connectivity-listener-leak.md) | A new connectivity listener is created on every app rebuild | P1 | — |
| ☐ | [FE-06](FE-06-ux-errors-and-small-bugs.md) | Raw exceptions shown to users, stale note screen, delete without confirmation | P2 | — |

### Feature: real reminders with system notifications
| ✓ | ID | Title | Priority | Depends on |
|---|---|---|---|---|
| ☐ | [REM-00](REM-00-overview.md) | **Overview and design** (read first) | — | — |
| ☑ | [REM-01](REM-01-notification-infrastructure.md) | Add the notification plugin, platform setup and `NotificationService` | P1 | — |
| ☑ | [REM-02](REM-02-permissions-ux.md) | Permission flow: notifications and exact alarms | P1 | REM-01 |
| ☑ | [REM-03](REM-03-scheduler-reconcile.md) | `ReminderScheduler`: schedule, reschedule and cancel from the DB | P1 | REM-01, FE-04 |
| ☑ | [REM-04](REM-04-notification-actions.md) | Done / Not done / Snooze actions, including when the app is killed | P1 | REM-03, FE-02 |
| ☑ | [REM-05](REM-05-repeating-reminders.md) | Repeating reminders move to the next occurrence | P1 | REM-03 |
| ☑ | [REM-06](REM-06-edit-reminder-ui-and-validation.md) | Edit-reminder UI and no past times on create | P1 | FE-02, REM-03 |
| ☑ | [REM-07](REM-07-backend-reminder-support.md) | Backend support: status enum, occurrence fields, idempotency | P1 | BE-04 |
| ☑ | [REM-08](REM-08-daily-weekly-settings.md) | Make the "Daily reminder" and "Weekly summary" settings work | P2 | REM-01, REM-02 |
| ☐ | [REM-09](REM-09-qa-matrix.md) | Device QA matrix and sign-off | P1 | REM-01…REM-06 |

### Repo hygiene
| ✓ | ID | Title | Priority | Depends on |
|---|---|---|---|---|
| ☑ | [REPO-01](REPO-01-git-baseline-and-ignores.md) | Commit the current work, fix `.gitignore`, remove tracked junk | P1 | — |
| ☐ | [REPO-02](REPO-02-config-docs-cleanup.md) | Bundle IDs, release signing, outdated docs, dead code | P2 | — |

## Suggested order

1. **REPO-01**: get a clean, committed baseline so every later PR is small.
2. **SEC-03**, **SEC-04**: quick fixes, but urgent.
3. **BE-01**, **FE-03**: stop the sync queue from jamming and creating duplicates.
4. **FE-04**, then **FE-02**: reliable offline writes. The reminder actions need these.
5. **FE-01**, **FE-05**, **BE-06**.
6. Reminder feature: **REM-01 → REM-02 → REM-03 → REM-07 → REM-04 → REM-05 → REM-06 → REM-08 → REM-09**.
7. **SEC-01 + SEC-02** together (large; this changes every API call). You can do it earlier if the backend is already public.
8. Everything else.
