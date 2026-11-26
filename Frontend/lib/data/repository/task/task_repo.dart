import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:notes_app/data/local/database/task_database_mapper.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/update_task_request_dto.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:uuid/uuid.dart';

class TaskRepo {
  final ApiClient client;
  final AppDatabase database;
  final OfflineSyncService syncService;

  TaskRepo({
    required this.client,
    required this.database,
    required this.syncService,
  });

  Future<List<TaskItem>> getCachedTasks(int userId) async {
    final cached = await database.getTasksForUser(userId);
    return cached.map(TaskDatabaseMapper.toTaskItem).toList();
  }

  Stream<List<TaskItem>> watchTasks(int userId) {
    return database
        .watchTasksForUser(userId)
        .map((tasks) => tasks.map(TaskDatabaseMapper.toTaskItem).toList());
  }

  /// Refreshes the cache from the server. Runs while no sync pass is
  /// running, so the merge can't undo a change that was just replayed.
  Future<List<TaskItem>> fetchAndCacheTasks(int userId) {
    return syncService.runExclusive(() => _fetchAndMerge(userId));
  }

  Future<List<TaskItem>> _fetchAndMerge(int userId) async {
    try {
      final response = await client.getAllTasks(userId);
      if (response.statusCode != 200) {
        return await getCachedTasks(userId);
      }

      final body = response.data;
      List<dynamic> items = [];
      if (body is Map && body['data'] is List) {
        items = body['data'] as List;
      } else if (body is List) {
        items = body;
      }

      final taskItems = items
          .map((item) => TaskItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      final companions = taskItems
          .map((t) => TaskDatabaseMapper.fromTaskItem(userId, t))
          .toList();

      await database.replaceServerTasks(userId, companions);
      return taskItems;
    } catch (e) {
      return getCachedTasks(userId);
    }
  }

  /// Saves the task locally, queues its upload (tagged with a new client id
  /// so a retried upload can't create it twice) and asks for a sync.
  Future<int> enqueueTask(CreateTaskRequestDto requestDto) async {
    final userId = requestDto.userId;
    final title = requestDto.title;
    if (title.trim().isEmpty) {
      throw ArgumentError('A task requires a title.');
    }

    final clientId = const Uuid().v4();
    final localId = await database.enqueueTask(
      userId: userId,
      title: title,
      description: requestDto.description,
      dueDate: requestDto.dueDate,
      dueTime: requestDto.dueTime,
      category: requestDto.category ?? 'General',
      priority: requestDto.priority ?? 'MEDIUM',
      status: requestDto.status ?? (requestDto.isCompleted ? 'COMPLETED' : 'PENDING'),
      isCompleted: requestDto.isCompleted,
      clientId: clientId,
      payload: jsonEncode({...requestDto.toJson(), 'clientId': clientId}),
    );
    unawaited(syncService.requestSync());
    return localId;
  }

  Future<void> toggleTaskStatus(int userId, int taskId, bool isCompleted) {
    return setTaskStatus(userId, taskId, isCompleted ? 'COMPLETED' : 'PENDING');
  }

  /// Sets PENDING / COMPLETED / REJECTED / MISSED locally and queues it
  /// (FE-02). For a task that was never uploaded the queued create carries the
  /// new status instead. Works offline.
  Future<void> setTaskStatus(int userId, int taskId, String status) async {
    final isCompleted = status == 'COMPLETED';
    await database.recordItemChange(
      entity: SyncEntity.task,
      userId: userId,
      itemId: taskId,
      op: 'status',
      changes: {'status': status, 'isCompleted': isCompleted},
      applyToRow: (localId) => _writeRow(
        localId,
        CachedTasksCompanion(
          status: Value(status),
          isCompleted: Value(isCompleted),
        ),
      ),
    );
    unawaited(syncService.requestSync());
  }

  /// Saves an edit locally and queues it (FE-02); works for unsynced tasks
  /// and offline. Throws [StateError] if the task doesn't exist.
  Future<void> updateTask(int userId, UpdateTaskRequestDto requestDto) async {
    final row = await _row(userId, requestDto.taskId);
    if (row == null) throw StateError('The task ${requestDto.taskId} was not found.');
    final status = requestDto.status ?? row.status;
    // The server's update requires isCompleted, so it is always sent.
    final isCompleted = requestDto.isCompleted ?? status == 'COMPLETED';
    final changes = {...requestDto.toJson(), 'isCompleted': isCompleted}..remove('taskId');
    await database.recordItemChange(
      entity: SyncEntity.task,
      userId: userId,
      itemId: requestDto.taskId,
      op: 'update',
      changes: changes,
      applyToRow: (localId) => _writeRow(
        localId,
        CachedTasksCompanion(
          title: _set(requestDto.title),
          description: _set(requestDto.description),
          dueDate: _set(requestDto.dueDate),
          dueTime: _set(requestDto.dueTime),
          category: _set(requestDto.category),
          priority: _set(requestDto.priority),
          status: Value(status),
          isCompleted: Value(isCompleted),
        ),
      ),
    );
    unawaited(syncService.requestSync());
  }

  /// Deletes locally and queues the delete (FE-02). A task that was never
  /// uploaded is dropped with its queued create; a synced one stays hidden
  /// until the server confirms, so a refresh can't bring it back.
  Future<void> deleteTask(int userId, int taskId) async {
    final deleted = await database.recordItemDelete(
      entity: SyncEntity.task,
      userId: userId,
      itemId: taskId,
    );
    if (deleted) unawaited(syncService.requestSync());
  }

  Future<CachedTask?> _row(int userId, int taskId) {
    return (database.select(database.cachedTasks)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isDeleted.equals(false) &
              (taskId < 0 ? t.id.equals(-taskId) : t.serverId.equals(taskId))))
        .getSingleOrNull();
  }

  Future<void> _writeRow(int localId, CachedTasksCompanion changes) async {
    await (database.update(database.cachedTasks)..where((t) => t.id.equals(localId)))
        .write(changes.copyWith(updatedAt: Value(DateTime.now().toIso8601String())));
  }

  static Value<T> _set<T>(T? value) => value == null ? const Value.absent() : Value(value);

  Future<List<TaskItem>> getTasksByDate(int userId, String date) async {
    final cached = await database.getTasksByDate(userId, date);
    return cached.map(TaskDatabaseMapper.toTaskItem).toList();
  }
}
