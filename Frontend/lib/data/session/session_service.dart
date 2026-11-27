import 'dart:async';
import 'dart:developer';

import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/secure_storage/token_store.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/local/shared_preference/preference_keys.dart';
import 'package:notes_app/data/repository/profile/profile_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';

/// The single source of truth for who is signed in on this device.
///
/// Nothing else reads or writes the stored user id. Riverpod controllers
/// follow [changes] through `sessionUserIdProvider`, so they rebuild for the
/// new user as soon as the session changes.
class SessionService {
  final Preference preference;
  final AppDatabase database;
  final OfflineSyncService syncService;
  final ProfileRepo profileRepo;

  /// SEC-02: the access token, in secure storage. Written only here.
  final TokenStore tokenStore;

  /// REM-03: cancels the signed-out user's scheduled reminder notifications
  /// (ReminderScheduler.cancelAllReminders). A callback, so the scheduler,
  /// which follows [changes], doesn't have to be built before the session.
  final Future<void> Function()? cancelReminders;

  // Synchronous, so providers already see the new user when login/logout
  // returns.
  final StreamController<int> _changes = StreamController<int>.broadcast(
    sync: true,
  );
  int _userId = 0;

  final StreamController<void> _expired = StreamController<void>.broadcast();
  bool _expiring = false;

  SessionService({
    required this.preference,
    required this.database,
    required this.syncService,
    required this.profileRepo,
    required this.tokenStore,
    this.cancelReminders,
  });

  /// The signed-in user, or 0 when signed out.
  int get userId => _userId;

  bool get isLoggedIn => _userId != 0;

  /// The new user id after every login and logout (0 = signed out).
  Stream<int> get changes => _changes.stream;

  /// Fires once each time [expire] signs the user out, so the UI can send
  /// them to the login screen.
  Stream<void> get expirations => _expired.stream;

  /// Restores the session saved by the last [login] when the app starts, and
  /// starts syncing for it.
  void restore() {
    _userId = preference.getInt(PreferenceKeys.USER_ID) ?? 0;
    syncService.start(_userId);
    if (isLoggedIn) _refreshProfile(_userId);
  }

  /// Signs [userId] in: saves it and their access [token], points the sync
  /// service at their queues and fetches their profile.
  ///
  /// The token goes to secure storage before anything is sent, so the first
  /// requests already carry it. A null [token] (a server from before SEC-01)
  /// clears any older one.
  Future<void> login(int userId, {AuthToken? token}) async {
    if (userId == 0) {
      throw ArgumentError.value(userId, 'userId', 'is not a valid user');
    }
    if (token != null) {
      await tokenStore.save(token);
    } else {
      await tokenStore.clear();
    }
    await preference.setInt(PreferenceKeys.USER_ID, userId);
    _userId = userId;
    syncService.setUserId(userId);
    _changes.add(userId);
    _refreshProfile(userId);
  }

  /// Local changes of the signed-in user that haven't reached the server.
  /// [logout] with `wipeLocalData` deletes them, so ask the user first when
  /// this isn't 0.
  Future<int> unsyncedChangeCount() =>
      isLoggedIn ? database.countUnsyncedChanges(_userId) : Future.value(0);

  /// Signs the current user out and stops syncing for them. With
  /// [wipeLocalData], their cached items, profile and unsynced changes are
  /// deleted from this device (check [unsyncedChangeCount] first).
  Future<void> logout({bool wipeLocalData = true}) async {
    final userId = _userId;
    await tokenStore.clear();
    await preference.remove(PreferenceKeys.USER_ID);
    _userId = 0;
    _changes.add(0);
    // Waits for a sync pass that is still uploading, so it can't write the
    // user's rows back after they were deleted.
    await syncService.stop();
    if (userId == 0) return;
    await cancelReminderNotifications(userId);
    if (wipeLocalData) {
      // Exclusive: a refresh that is still running finishes before the wipe.
      await syncService.runExclusive(() => database.deleteUserData(userId));
    }
  }

  /// SEC-02: the server rejected the session (401: token expired, invalid, or
  /// missing once the server requires one). Signs out once, however many
  /// requests failed, and tells [expirations] listeners.
  ///
  /// Local data is kept: unsynced changes stay queued and upload when the
  /// same user signs in again. Returns whether this call signed out.
  Future<bool> expire() async {
    if (!isLoggedIn || _expiring) return false;
    _expiring = true;
    try {
      await logout(wipeLocalData: false);
      _expired.add(null);
      return true;
    } finally {
      _expiring = false;
    }
  }

  /// Logout hook (REM-03): cancels every scheduled reminder notification of
  /// [userId], so a signed-out user's reminders don't keep firing. Failures
  /// are logged; they must not stop the logout.
  Future<void> cancelReminderNotifications(int userId) async {
    try {
      await cancelReminders?.call();
    } catch (error, stackTrace) {
      log('Failed to cancel reminder notifications: $error', stackTrace: stackTrace);
    }
  }

  /// The user id saved by the last [login], read without restoring the
  /// session. For the notification background isolate (REM-04), which must
  /// not act for a user who has signed out since the notification was shown.
  static int storedUserId(Preference preference) =>
      preference.getInt(PreferenceKeys.USER_ID) ?? 0;

  void _refreshProfile(int userId) {
    unawaited(
      profileRepo.refreshProfile(userId).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        log('Failed to refresh the profile: $error', stackTrace: stackTrace);
      }),
    );
  }

  Future<void> dispose() async {
    await _changes.close();
    await _expired.close();
  }
}
