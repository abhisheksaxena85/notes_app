import 'dart:async';
import 'dart:developer';

import 'package:notes_app/data/local/database/app_database.dart';
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

  // Synchronous, so providers already see the new user when login/logout
  // returns.
  final StreamController<int> _changes = StreamController<int>.broadcast(
    sync: true,
  );
  int _userId = 0;

  SessionService({
    required this.preference,
    required this.database,
    required this.syncService,
    required this.profileRepo,
  });

  /// The signed-in user, or 0 when signed out.
  int get userId => _userId;

  bool get isLoggedIn => _userId != 0;

  /// The new user id after every login and logout (0 = signed out).
  Stream<int> get changes => _changes.stream;

  /// Restores the session saved by the last [login] when the app starts, and
  /// starts syncing for it.
  void restore() {
    _userId = preference.getInt(PreferenceKeys.USER_ID) ?? 0;
    syncService.start(_userId);
    if (isLoggedIn) _refreshProfile(_userId);
  }

  /// Signs [userId] in: saves it, points the sync service at their queues and
  /// fetches their profile.
  ///
  /// SEC-02 adds the auth token here; it belongs in secure storage, not in
  /// SharedPreferences.
  Future<void> login(int userId) async {
    if (userId == 0) {
      throw ArgumentError.value(userId, 'userId', 'is not a valid user');
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

  /// Logout hook for REM-03: cancel every scheduled reminder notification of
  /// [userId], so a signed-out user's reminders don't keep firing. Nothing is
  /// scheduled on the device yet, so there is nothing to cancel.
  Future<void> cancelReminderNotifications(int userId) async {}

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

  Future<void> dispose() => _changes.close();
}
