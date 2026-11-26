/// The kinds of items the offline queue uploads.
enum SyncEntity { note, task, reminder }

/// A queued change the server refused for good (a 4xx other than 408/429, or
/// `success:false`). Automatic sync skips it until the user retries it;
/// discarding it drops the change.
class SyncFailure {
  final SyncEntity entity;

  /// `create` (a row in a Pending* table) or `update` / `status` / `delete`
  /// (a row in PendingMutations).
  final String operation;

  /// Row id in the queue table the failure came from.
  final int queueId;

  /// Local row id of the cached item, when it still exists.
  final int? localId;

  final String title;
  final String? lastError;
  final int attempts;

  const SyncFailure({
    required this.entity,
    this.operation = 'create',
    required this.queueId,
    required this.localId,
    required this.title,
    required this.lastError,
    required this.attempts,
  });
}
