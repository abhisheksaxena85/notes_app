class UpdateTaskRequestDto {
  final int taskId;
  final String? title;
  final String? description;
  final String? dueDate;
  final String? dueTime;
  final String? category;
  final String? priority;
  final String? status;
  final bool? isCompleted;

  UpdateTaskRequestDto({
    required this.taskId,
    this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.category,
    this.priority,
    this.status,
    this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'dueDate': dueDate,
      if (dueTime != null) 'dueTime': dueTime,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (isCompleted != null) 'isCompleted': isCompleted,
    };
  }

  factory UpdateTaskRequestDto.fromJson(Map<String, dynamic> json) {
    return UpdateTaskRequestDto(
      taskId: json['taskId'] as int? ?? 0,
      title: json['title'] as String?,
      description: json['description'] as String?,
      dueDate: json['dueDate'] as String?,
      dueTime: json['dueTime'] as String?,
      category: json['category'] as String?,
      priority: json['priority'] as String?,
      status: json['status'] as String?,
      isCompleted: json['isCompleted'] as bool?,
    );
  }
}
