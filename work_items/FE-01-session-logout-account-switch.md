# FE-01 — Logging out and in as another user shows the previous user's data

**Type:** Bug (privacy) · **Priority:** P0 · **Area:** Frontend · **Depends on:** none

## Problem
Session state is spread across a global variable, SharedPreferences and long-lived providers, and logout only clears some of it.

Evidence:
- `Frontend/lib/viewmodel/controllers.dart`: `homeController`, `taskController`, `reminderController`, `profileController` and `noteDetailsController` are global `AsyncNotifierProvider`s (**not** `autoDispose`, **not** families). Their `build()` reads the user id once and subscribes to `watchNotes(userId)` / `watchTasks(userId)` / `watchReminders(userId)` (for example `viewmodel/home/home_viewmodel.dart:18-46`).
- Logout (`views/screens/profile/widgets/build_profile_widget.dart:1280-1292`) only sets `USER_ID` to 0 in prefs, sets `IS_LOGGED_IN=false` and the global `USER_ID = 0`, then navigates. It **doesn't invalidate any provider**, doesn't reset `OfflineSyncService`, and doesn't clear the Drift cache.
- Login (`viewmodel/auth/login/login_viewmodel.dart:81-102`) saves the prefs id but **never sets the global `USER_ID`** (`main.dart:19`) or `IS_LOGGED_IN=true`. It uses `Navigator.push`, so **Back on the dashboard returns to the login screen**.
- Register flow: check it the same way.

### Result
User A logs out, user B logs in in the same app session. The providers are still alive and still watching **A's** rows, so B sees A's notes, tasks and reminders, and B's data doesn't show until the app restarts. A's cached notes also stay on disk in plain SQLite after logout.

## Proposed fix
1. Create `lib/data/session/session_service.dart` (registered in get_it) as the single source of truth:
   - `int get userId`, `bool get isLoggedIn`, `Stream<int> changes`.
   - `Future<void> login(int userId, {String? token})`: persist the id (and the token for SEC-02), call `OfflineSyncService.setUserId`, refresh the profile.
   - `Future<void> logout({bool wipeLocalData = true})`: clear prefs and token, `OfflineSyncService.stop()` (add it), cancel all reminder notifications (REM-03 hook), and optionally delete the user's cached and pending rows. **Warn first if there are unsynced pending items**, since wiping would lose them.
2. Remove the global `USER_ID` from `main.dart`. Replace its uses (`splash_screen.dart:113`, `build_profile_widget.dart:92,250,461,1161`) and every `getIt<Preference>().getInt(PreferenceKeys.USER_ID)` with the session service.
3. Riverpod: add `final sessionUserIdProvider = StateProvider<int>(...)` (or a `Notifier`) and have each controller `ref.watch(sessionUserIdProvider)` in `build()`, so a user change rebuilds them automatically. Also call `ref.invalidate(...)` on all controllers during logout as a safety net.
4. Navigation: after login or register, `Navigator.pushAndRemoveUntil(... DashboardScreen ..., (_) => false)`.
5. Remove `IS_LOGGED_IN` if it isn't needed, or set it on login.

## Acceptance criteria
- [ ] Log in as A, create data, log out, log in as B: B sees only B's data immediately, without restarting.
- [ ] Back on the dashboard after login exits the app instead of showing the login screen.
- [ ] After logout, the Drift tables have no rows for A (when wipe is on). If A had unsynced items, a confirmation dialog appears first.
- [ ] Widget or integration test for the A → B switch using `AppDatabase.forTesting` and a fake `ApiClient`.
