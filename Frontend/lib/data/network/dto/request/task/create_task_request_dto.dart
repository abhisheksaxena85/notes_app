class CreateTaskRequestDto {
  final int userId;
  final String title;
  final String? description;
  final String? dueDate;
  final String? dueTime;
  final String? category;
  final String? priority;
  final String? status;
  final bool isCompleted;

  CreateTaskRequestDto({
    required this.userId,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.category,
    this.priority,
    this.status,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'dueDate': dueDate,
      if (dueTime != null) 'dueTime': dueTime,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      'isCompleted': isCompleted,
    };
  }

  factory CreateTaskRequestDto.fromJson(Map<String, dynamic> json) {
    return CreateTaskRequestDto(
      userId: json['userId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: json['dueDate'] as String?,
      dueTime: json['dueTime'] as String?,
      category: json['category'] as String?,
      priority: json['priority'] as String?,
      status: json['status'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
