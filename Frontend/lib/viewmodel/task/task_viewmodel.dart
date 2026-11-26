import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/update_task_request_dto.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/viewmodel/task/task_state.dart';
import 'package:notes_app/viewmodel/controllers.dart';

class TaskViewmodel extends AsyncNotifier<TaskState> {
  final TaskRepo _taskRepo = getIt<TaskRepo>();

  @override
  Future<TaskState> build() async {
    final userId = ref.watch(sessionUserIdProvider);
    final cached = await _taskRepo.getCachedTasks(userId);

    final subscription = _taskRepo.watchTasks(userId).listen((tasks) {
      if (state.hasValue) {
        state = AsyncData(state.value!.copyWith(tasks: tasks));
      }
    }, onError: (Object err, StackTrace st) {
      log('Failed to watch tasks: $err', stackTrace: st);
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    if (userId != 0) {
      unawaited(_refreshTasks(userId));
    }

    return TaskState(tasks: cached);
  }

  int getUserId() {
    return ref.read(sessionUserIdProvider);
  }

  Future<void> refreshTasks() async {
    final userId = getUserId();
    if (userId != 0) {
      await _taskRepo.fetchAndCacheTasks(userId);
    }
  }

  Future<void> _refreshTasks(int userId) async {
    try {
      await _taskRepo.fetchAndCacheTasks(userId);
    } catch (e, st) {
      log('Failed to fetch tasks: $e', stackTrace: st);
    }
  }

  Future<void> createTask({
    required String title,
    String? description,
    String? dueDate,
    String? dueTime,
    String? category,
    String? priority,
  }) async {
    final userId = getUserId();
    final request = CreateTaskRequestDto(
      userId: userId,
      title: title,
      description: description,
      dueDate: dueDate,
      dueTime: dueTime,
      category: category,
      priority: priority,
    );

    await _taskRepo.enqueueTask(request);
  }

  Future<void> toggleTaskStatus(int taskId, bool isCompleted) async {
    final userId = getUserId();
    await _taskRepo.toggleTaskStatus(userId, taskId, isCompleted);
  }

  Future<void> setTaskStatus(int taskId, String status) async {
    final userId = getUserId();
    await _taskRepo.setTaskStatus(userId, taskId, status);
  }

  Future<void> updateTask(UpdateTaskRequestDto requestDto) async {
    final userId = getUserId();
    await _taskRepo.updateTask(userId, requestDto);
  }

  Future<void> deleteTask(int taskId) async {
    final userId = getUserId();
    await _taskRepo.deleteTask(userId, taskId);
  }
}
