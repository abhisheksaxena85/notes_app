import 'dart:async';
import 'dart:developer';

import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';

class OfflineSyncService {
  final NoteRepo noteRepo;
  final TaskRepo? taskRepo;
  final ReminderRepo? reminderRepo;
  final InternetConnectionChecker connectionChecker;

  StreamSubscription<InternetConnectionStatus>? _subscription;
  int? _userId;
  Future<void>? _running;
  bool _syncAgain = false;

  OfflineSyncService({
    required this.noteRepo,
    this.taskRepo,
    this.reminderRepo,
    required this.connectionChecker,
  });

  void start(int userId) {
    _userId = userId;
    _subscription ??= connectionChecker.onStatusChange.listen((status) {
      if (status == InternetConnectionStatus.connected) {
        unawaited(syncPendingAll());
      }
    });
    unawaited(syncPendingAll());
  }

  void setUserId(int userId) {
    _userId = userId;
    unawaited(syncPendingAll());
  }

  /// Runs one sync pass. If a pass is already running, it is asked to go
  /// round once more and the returned future completes when it finishes.
  Future<void> syncPendingAll() {
    final running = _running;
    if (running != null) {
      _syncAgain = true;
      return running;
    }
    if (_userId == null || _userId == 0) return Future.value();

    final run = _runSyncLoop();
    _running = run;
    return run;
  }

  Future<void> _runSyncLoop() async {
    try {
      do {
        _syncAgain = false;
        final userId = _userId;
        if (userId != null && userId != 0) {
          // Each entity type syncs on its own, so a failure in one queue does
          // not stop the others.
          await _syncEntity('notes', () => noteRepo.syncQueuedNotes(userId));
          if (taskRepo != null) {
            await _syncEntity('tasks', () => taskRepo!.syncQueuedTasks(userId));
          }
          if (reminderRepo != null) {
            await _syncEntity(
              'reminders',
              () => reminderRepo!.syncQueuedReminders(userId),
            );
          }
        }
      } while (_syncAgain);
    } finally {
      _running = null;
    }
  }

  Future<void> _syncEntity(String name, Future<void> Function() sync) async {
    try {
      await sync();
    } catch (error, stackTrace) {
      log('Failed to sync queued $name: $error', stackTrace: stackTrace);
    }
  }

  Future<void> syncPendingNotes() => syncPendingAll();

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
