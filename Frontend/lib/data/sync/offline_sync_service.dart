import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/sync/sync_queue_processor.dart';
import 'package:notes_app/utils/services/connectivity_service.dart';

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
  final ConnectivityService? connectivity;
  final Duration minRetryDelay;
  final Duration maxRetryDelay;
  final SyncQueueProcessor _processor;

  StreamSubscription<bool>? _subscription;
  int? _userId;
  Future<void>? _running;
  bool _syncAgain = false;
  bool _disposed = false;

  /// Sync passes and refreshes run one at a time (see [runExclusive]).
  Future<void> _lockTail = Future.value();

  Timer? _retryTimer;
  DateTime? _retryAt;
  Duration? _scheduledDelay;
  late Duration _retryDelay = minRetryDelay;

  OfflineSyncService({
    required ApiClient client,
    required this.database,
    this.connectivity,
    this.minRetryDelay = const Duration(seconds: 5),
    this.maxRetryDelay = const Duration(minutes: 5),
  }) : _processor = SyncQueueProcessor(client: client, database: database);

  final StreamController<void> _completions = StreamController<void>.broadcast();

  int? get userId => _userId;

  /// Fires after every sync pass (W-01: the home-screen widgets refresh).
  Stream<void> get completions => _completions.stream;

  /// Starts listening for connectivity and syncs for [userId] right away.
  void start(int userId) {
    _userId = userId;
    _subscription ??= connectivity?.online.listen((online) {
      if (online) _automaticTrigger();
    });
    unawaited(requestSync());
  }

  void setUserId(int userId) {
    if (_userId != userId) _resetBackoff();
    _userId = userId;
    unawaited(requestSync());
  }

  /// Stops syncing for the current user (logout). A scheduled retry is
  /// dropped and a pass that is still running finishes first. Connectivity
  /// events are still received, but nothing syncs until [setUserId].
  Future<void> stop() async {
    _userId = null;
    _syncAgain = false;
    _resetBackoff();
    await _running;
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

    final run = runExclusive(_runSyncLoop);
    _running = run;
    return run;
  }

  /// Runs [action] while no sync pass is running, and keeps passes from
  /// starting until it is done. Refreshes use this so a server list fetched
  /// before a queued change was replayed can't overwrite that change.
  Future<T> runExclusive<T>(Future<T> Function() action) {
    final result = _lockTail.then((_) => action());
    _lockTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Items the server refused for good.
  Stream<List<SyncFailure>> watchFailures(int userId) =>
      database.watchSyncFailures(userId);

  /// Puts failed items back in the queue and syncs.
  Future<void> retryFailed(List<SyncFailure> failures) async {
    for (final failure in failures) {
      await database.resetSyncFailure(failure);
    }
    await requestSync();
  }

  /// Drops a failed change: it is never sent. A never-synced item is removed;
  /// for other items the next refresh restores the server's version.
  Future<void> discardFailed(SyncFailure failure) =>
      database.discardSyncFailure(failure);

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
        // Per entity: creates first, so changes queued against a new item
        // can be sent to its server id in the same pass.
        for (final entity in SyncEntity.values) {
          for (final (stage, upload) in [
            ('creates', _processor.uploadCreates),
            ('changes', _processor.replayMutations),
          ]) {
            try {
              if (await upload(entity, userId)) pausedByTransientError = true;
            } catch (error, stackTrace) {
              // A local failure (database) in one queue must not stop the others.
              pausedByTransientError = true;
              log('Failed to sync ${entity.name} $stage: $error', stackTrace: stackTrace);
            }
          }
        }
        // After a transient error, requests made during the pass wait for the
        // scheduled retry instead of hitting the network again right away.
      } while (_syncAgain && !pausedByTransientError);
    } finally {
      _running = null;
    }
    if (_disposed) return;
    _completions.add(null);
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
    await _completions.close();
  }
}
