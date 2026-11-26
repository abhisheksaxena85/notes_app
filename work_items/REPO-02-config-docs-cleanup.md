# REPO-02 — Bundle IDs, release signing, outdated docs, dead code

**Type:** Hygiene · **Priority:** P2 · **Area:** Frontend config, docs · **Depends on:** none

## Items
1. **macOS bundle id** is still the template value: `Frontend/macos/Runner/Configs/AppInfo.xcconfig:11` `PRODUCT_BUNDLE_IDENTIFIER = com.example.notesApp`, while Android and iOS use `com.devquorix.daymark`. Align it (and `PRODUCT_NAME` / copyright there).
2. **Android release signing** uses the debug key (`android/app/build.gradle.kts`, `signingConfig = signingConfigs.getByName("debug")`). Add a `key.properties`-based release signing config (file gitignored) with a fallback to debug for local builds. Document it in `Frontend/README.md`.
3. `pubspec.yaml` `description: "A new Flutter project."` → describe Daymark. Also remove the template comment noise if you like.
4. **Docs out of date**:
   - `Frontend/docs/IMPLEMENTATION_STATUS.md` still marks Edit profile, Change password, Delete account, JSON export and Help/About as "In Progress", but the UI exists in `build_profile_widget.dart`. Check each one and update. Add rows for Tasks, Reminders and Notifications.
   - `Frontend/docs/API_MAPPING.md` has no `/tasks/*` or `/reminders/*` endpoints and no `day-activity`. Add them (REM-07 adds `complete-occurrence`).
   - Root `instruction_work.md` vs `Frontend/instruction_work.md` (see REPO-01).
5. **Dead code**: `Backend/.../config/JwtConfig.java` (empty, used in SEC-01), `Frontend/lib/data/network/config/api_config.dart` (empty class), `RetryInterceptor` (no-op, see FE-06), `PreferenceKeys.IS_LOGGED_IN` (written once, never read, see FE-01), `OfflineSyncService.syncPendingNotes` alias.
6. **Big file**: `views/screens/profile/widgets/build_profile_widget.dart` is 1,826 lines (account, preferences, notifications, privacy, data & backup, help, about and logout sheets in one file). Split each sheet into its own widget file under `views/screens/profile/widgets/sheets/`. Do this **after** REM-08 and FE-01 touch it, to avoid conflicts. Pure refactor, no behaviour change.

## Acceptance criteria
- [ ] `flutter analyze` is clean. App builds on Android, iOS and macOS.
- [ ] Docs match the code.
