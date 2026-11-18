import 'package:notes_app/data/network/dto/response/item_status.dart';

class TaskItem {
  final int? taskId;
  final String title;
  final String? description;
  final String? dueDate;
  final String? dueTime;
  final String? category;
  final String priority;
  final String status; // PENDING, COMPLETED, REJECTED, MISSED
  final bool isCompleted;
  final String? createdAt;
  final String? updatedAt;

  TaskItem({
    this.taskId,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.category,
    this.priority = 'MEDIUM',
    this.status = 'PENDING',
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Status to render: an overdue PENDING task is shown as MISSED.
  String effectiveStatus([DateTime? now]) {
    if (isCompleted) return ItemStatus.completed;
    return ItemStatus.effective(
      status,
      ItemStatus.dueMoment(dueDate, dueTime),
      now ?? DateTime.now(),
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['taskId'] ?? json['id'];
    int? parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId);
    }

    final rawCompleted = json['isCompleted'] ?? json['completed'];
    bool parsedCompleted = false;
    if (rawCompleted is bool) {
      parsedCompleted = rawCompleted;
    } else if (rawCompleted is String) {
      parsedCompleted = rawCompleted.toLowerCase() == 'true';
    }

    final statusStr = json['status']?.toString().toUpperCase() ??
        (parsedCompleted ? 'COMPLETED' : 'PENDING');

    return TaskItem(
      taskId: parsedId,
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      dueDate: json['dueDate']?.toString(),
      dueTime: json['dueTime']?.toString(),
      category: json['category']?.toString() ?? 'General',
      priority: json['priority']?.toString().toUpperCase() ?? 'MEDIUM',
      status: statusStr,
      isCompleted: parsedCompleted || statusStr == 'COMPLETED',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (taskId != null) 'taskId': taskId,
      'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'dueDate': dueDate,
      if (dueTime != null) 'dueTime': dueTime,
      if (category != null) 'category': category,
      'priority': priority,
      'status': status,
      'isCompleted': isCompleted,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  TaskItem copyWith({
    int? taskId,
    String? title,
    String? description,
    String? dueDate,
    String? dueTime,
    String? category,
    String? priority,
    String? status,
    bool? isCompleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return TaskItem(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
