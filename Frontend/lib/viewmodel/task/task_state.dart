import 'package:notes_app/data/network/dto/response/task/task_item.dart';

class TaskState {
  final List<TaskItem> tasks;
  final bool isLoading;
  final String? errorMessage;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TaskState copyWith({
    List<TaskItem>? tasks,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
