import 'dart:convert';

import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/task_database_mapper.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/update_task_request_dto.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';

class TaskRepo {
  final ApiClient client;
  final AppDatabase database;

  TaskRepo({required this.client, required this.database});

  Future<List<TaskItem>> getCachedTasks(int userId) async {
    final cached = await database.getTasksForUser(userId);
    return cached.map(TaskDatabaseMapper.toTaskItem).toList();
  }

  Stream<List<TaskItem>> watchTasks(int userId) {
    return database
        .watchTasksForUser(userId)
        .map((tasks) => tasks.map(TaskDatabaseMapper.toTaskItem).toList());
  }

  Future<List<TaskItem>> fetchAndCacheTasks(int userId) async {
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

  Future<int> enqueueTask(CreateTaskRequestDto requestDto) {
    final userId = requestDto.userId;
    final title = requestDto.title;
    if (title.trim().isEmpty) {
      throw ArgumentError('A task requires a title.');
    }

    return database.enqueueTask(
      userId: userId,
      title: title,
      description: requestDto.description,
      dueDate: requestDto.dueDate,
      dueTime: requestDto.dueTime,
      category: requestDto.category ?? 'General',
      priority: requestDto.priority ?? 'MEDIUM',
      status: requestDto.status ?? (requestDto.isCompleted ? 'COMPLETED' : 'PENDING'),
      isCompleted: requestDto.isCompleted,
      payload: jsonEncode(requestDto.toJson()),
    );
  }

  Future<void> syncQueuedTasks(int userId) async {
    final pendingList = await database.getPendingTasks(userId);
    for (final pending in pendingList) {
      try {
        final decoded = jsonDecode(pending.payload);
        if (decoded is! Map) continue;

        final request = CreateTaskRequestDto.fromJson(
          Map<String, dynamic>.from(decoded),
        );

        final response = await client.createTask(request);
        if (response.statusCode == null ||
            response.statusCode! < 200 ||
            response.statusCode! >= 300) {
          continue;
        }

        final body = response.data;
        int? serverId;
        if (body is Map && body['data'] is Map) {
          final data = body['data'] as Map;
          final rawId = data['taskId'] ?? data['id'];
          if (rawId is int) {
            serverId = rawId;
          } else if (rawId is String) {
            serverId = int.tryParse(rawId);
          }
        }

        if (serverId != null) {
          await database.completePendingTask(
            queueId: pending.id,
            localTaskId: pending.localTaskId,
            serverId: serverId,
          );
        }
      } catch (_) {
        // Network or server error; keep in queue for next sync
        break;
      }
    }
  }

  Future<void> toggleTaskStatus(int userId, int taskId, bool isCompleted) {
    return setTaskStatus(userId, taskId, isCompleted ? 'COMPLETED' : 'PENDING');
  }

  /// Sets PENDING / COMPLETED / REJECTED / MISSED. For a task that has not
  /// synced yet (negative id) the queued create payload is patched too, so the
  /// server receives the latest status instead of the one it was queued with.
  Future<void> setTaskStatus(int userId, int taskId, String status) async {
    final isCompleted = status == 'COMPLETED';
    await database.transaction(() async {
      await database.updateTaskStatus(
        taskId: taskId,
        status: status,
        isCompleted: isCompleted,
      );
      if (taskId < 0) {
        final pending = await database.getPendingTaskForLocalId(-taskId);
        if (pending != null) {
          final decoded = jsonDecode(pending.payload);
          if (decoded is Map) {
            final payload = Map<String, dynamic>.from(decoded)
              ..['status'] = status
              ..['isCompleted'] = isCompleted;
            await database.updatePendingTaskPayload(pending.id, jsonEncode(payload));
          }
        }
      }
    });

    if (taskId > 0) {
      try {
        await client.toggleTaskStatus(taskId, status: status);
      } catch (_) {
        // Ignored for offline tolerance
      }
    }
  }

  Future<void> updateTask(int userId, UpdateTaskRequestDto requestDto) async {
    if (requestDto.taskId > 0) {
      final response = await client.updateTask(requestDto);
      if (response.statusCode == 200 && response.data is Map) {
        final body = response.data as Map;
        if (body['data'] is Map) {
          final updated = TaskItem.fromJson(Map<String, dynamic>.from(body['data']));
          await database.saveServerTask(
            TaskDatabaseMapper.fromTaskItem(userId, updated),
          );
        }
      }
    }
  }

  Future<void> deleteTask(int userId, int taskId) async {
    await database.deleteCachedTask(taskId);
    if (taskId > 0) {
      try {
        await client.deleteTask(taskId);
      } catch (_) {
        // Ignored for offline tolerance
      }
    }
  }

  Future<List<TaskItem>> getTasksByDate(int userId, String date) async {
    final cached = await database.getTasksByDate(userId, date);
    return cached.map(TaskDatabaseMapper.toTaskItem).toList();
  }
}
