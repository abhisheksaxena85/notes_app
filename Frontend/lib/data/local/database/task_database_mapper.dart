import 'package:drift/drift.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';

class TaskDatabaseMapper {
  static TaskItem toTaskItem(CachedTask task) {
    return TaskItem(
      taskId: task.serverId ?? -task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      dueTime: task.dueTime,
      category: task.category,
      priority: task.priority,
      status: task.status,
      isCompleted: task.isCompleted,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    );
  }

  static CachedTasksCompanion fromTaskItem(int userId, TaskItem task) {
    return CachedTasksCompanion.insert(
      userId: userId,
      serverId: task.taskId != null && task.taskId! > 0 ? Value(task.taskId) : const Value.absent(),
      title: task.title,
      description: Value(task.description),
      dueDate: Value(task.dueDate),
      dueTime: Value(task.dueTime),
      category: Value(task.category ?? 'General'),
      priority: Value(task.priority),
      status: Value(task.status),
      isCompleted: Value(task.isCompleted),
      createdAt: Value(task.createdAt),
      updatedAt: Value(task.updatedAt),
      isPending: const Value(false),
    );
  }
}
