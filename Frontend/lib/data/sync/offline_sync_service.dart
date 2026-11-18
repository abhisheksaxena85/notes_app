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
  bool _isSyncing = false;
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

  Future<void> syncPendingAll() async {
    if (_isSyncing) {
      _syncAgain = true;
      return;
    }
    if (_userId == null || _userId == 0) return;

    _isSyncing = true;
    try {
      do {
        _syncAgain = false;
        final userId = _userId;
        if (userId != null && userId != 0) {
          await noteRepo.syncQueuedNotes(userId);
          if (taskRepo != null) {
            await taskRepo!.syncQueuedTasks(userId);
          }
          if (reminderRepo != null) {
            await reminderRepo!.syncQueuedReminders(userId);
          }
        }
      } while (_syncAgain);
    } catch (error, stackTrace) {
      log('Failed to sync queued items: $error', stackTrace: stackTrace);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncPendingNotes() => syncPendingAll();

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
