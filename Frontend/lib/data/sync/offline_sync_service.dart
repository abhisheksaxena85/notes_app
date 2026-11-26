import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/sync/sync_queue_processor.dart';

/// The only way queued offline changes reach the server.
///
/// Repositories write locally, then call [requestSync]. Calls while a sync is
/// running are folded into it (at most one more pass runs afterwards), so two
/// triggers can never upload the same queued item twice.
///
/// Each entity type syncs on its own. A transient failure (offline, timeout,
/// 5xx) stops that type and schedules a retry with exponential backoff
/// ([minRetryDelay] doubling up to [maxRetryDelay]); an item the server refuses
/// for good is marked failed, skipped, and listed by [watchFailures] so the UI
/// can offer retry and discard.
class OfflineSyncService {
  final AppDatabase database;
  final InternetConnectionChecker? connectionChecker;
  final Duration minRetryDelay;
  final Duration maxRetryDelay;
  final SyncQueueProcessor _processor;

  StreamSubscription<InternetConnectionStatus>? _subscription;
  int? _userId;
  Future<void>? _running;
  bool _syncAgain = false;
  bool _disposed = false;

  Timer? _retryTimer;
  DateTime? _retryAt;
  Duration? _scheduledDelay;
  late Duration _retryDelay = minRetryDelay;

  OfflineSyncService({
    required ApiClient client,
    required this.database,
    this.connectionChecker,
    this.minRetryDelay = const Duration(seconds: 5),
    this.maxRetryDelay = const Duration(minutes: 5),
  }) : _processor = SyncQueueProcessor(client: client, database: database);

  int? get userId => _userId;

  /// Starts listening for connectivity and syncs for [userId] right away.
  void start(int userId) {
    _userId = userId;
    _subscription ??= connectionChecker?.onStatusChange.listen((status) {
      if (status == InternetConnectionStatus.connected) {
        _automaticTrigger();
      }
    });
    unawaited(requestSync());
  }

  void setUserId(int userId) {
    if (_userId != userId) _resetBackoff();
    _userId = userId;
    unawaited(requestSync());
  }

  /// Called when the app comes back to the foreground.
  void onAppResumed() => _automaticTrigger();

  /// Uploads everything queued for the current user. Completes when the
  /// queues have been processed (including a pass that was already running).
  Future<void> requestSync() {
    final running = _running;
    if (running != null) {
      _syncAgain = true;
      return running;
    }
    final userId = _userId;
    if (_disposed || userId == null || userId == 0) return Future.value();

    final run = _runSyncLoop();
    _running = run;
    return run;
  }

  /// Items the server refused for good.
  Stream<List<SyncFailure>> watchFailures(int userId) =>
      database.watchSyncFailures(userId);

  /// Puts failed items back in the queue and syncs.
  Future<void> retryFailed(List<SyncFailure> failures) async {
    for (final failure in failures) {
      await database.resetSyncFailure(failure.entity, failure.queueId);
    }
    await requestSync();
  }

  /// Drops a failed item: the change is never sent and the local copy of a
  /// never-synced item is removed.
  Future<void> discardFailed(SyncFailure failure) =>
      database.discardQueuedCreate(failure.entity, failure.queueId);

  /// The delay of the pending automatic retry, if one is scheduled.
  @visibleForTesting
  Duration? get scheduledRetryDelay =>
      _retryTimer?.isActive == true ? _scheduledDelay : null;

  Future<void> _runSyncLoop() async {
    var pausedByTransientError = false;
    try {
      do {
        _syncAgain = false;
        final userId = _userId;
        if (userId == null || userId == 0) break;
        pausedByTransientError = false;
        for (final (name, upload) in [
          ('notes', _processor.uploadNotes),
          ('tasks', _processor.uploadTasks),
          ('reminders', _processor.uploadReminders),
        ]) {
          try {
            if (await upload(userId)) pausedByTransientError = true;
          } catch (error, stackTrace) {
            // A local failure (database) in one queue must not stop the others.
            pausedByTransientError = true;
            log('Failed to sync queued $name: $error', stackTrace: stackTrace);
          }
        }
        // After a transient error, requests made during the pass wait for the
        // scheduled retry instead of hitting the network again right away.
      } while (_syncAgain && !pausedByTransientError);
    } finally {
      _running = null;
    }
    if (_disposed) return;
    if (pausedByTransientError) {
      _scheduleRetry();
    } else {
      _resetBackoff();
    }
  }

  void _scheduleRetry() {
    final delay = _retryDelay;
    _schedule(delay);
    final doubled = delay * 2;
    _retryDelay = doubled > maxRetryDelay ? maxRetryDelay : doubled;
  }

  void _schedule(Duration delay) {
    _retryTimer?.cancel();
    _scheduledDelay = delay;
    _retryAt = DateTime.now().add(delay);
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      _retryAt = null;
      unawaited(requestSync());
    });
  }

  void _resetBackoff() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryAt = null;
    _retryDelay = minRetryDelay;
  }

  /// Connectivity and app-resume events. While backing off they only bring
  /// the pending retry forward to [minRetryDelay], so a flapping connection
  /// can't trigger a full retry on every change.
  void _automaticTrigger() {
    final retryAt = _retryAt;
    if (_retryTimer?.isActive != true || retryAt == null) {
      unawaited(requestSync());
      return;
    }
    if (retryAt.difference(DateTime.now()) > minRetryDelay) {
      _schedule(minRetryDelay);
    }
  }

  /// Stops automatic syncing and waits for a pass that is still running.
  Future<void> dispose() async {
    _disposed = true;
    _resetBackoff();
    await _subscription?.cancel();
    await _running;
  }
}
