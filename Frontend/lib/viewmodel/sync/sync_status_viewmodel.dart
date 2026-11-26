import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/viewmodel/controllers.dart';

/// Queued changes the server refused, with retry and discard actions.
class SyncStatusViewmodel extends StreamNotifier<List<SyncFailure>> {
  OfflineSyncService get _sync => getIt<OfflineSyncService>();

  @override
  Stream<List<SyncFailure>> build() {
    final userId = ref.watch(sessionUserIdProvider);
    return _sync.watchFailures(userId);
  }

  Future<void> retryAll() => _sync.retryFailed(state.value ?? const []);

  Future<void> retry(SyncFailure failure) => _sync.retryFailed([failure]);

  Future<void> discard(SyncFailure failure) => _sync.discardFailed(failure);
}
