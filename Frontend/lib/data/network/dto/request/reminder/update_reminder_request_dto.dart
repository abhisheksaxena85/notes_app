class UpdateReminderRequestDto {
  final int reminderId;
  final String? title;
  final String? remindAt;
  final String? dueDate;
  final String? dueTime;
  final String? category;
  final String? status;
  final String? repeatInterval;

  UpdateReminderRequestDto({
    required this.reminderId,
    this.title,
    this.remindAt,
    this.dueDate,
    this.dueTime,
    this.category,
    this.status,
    this.repeatInterval,
  });

  Map<String, dynamic> toJson() {
    return {
      'reminderId': reminderId,
      if (title != null) 'title': title,
      if (remindAt != null) 'remindAt': remindAt,
      if (dueDate != null) 'dueDate': dueDate,
      if (dueTime != null) 'dueTime': dueTime,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (repeatInterval != null) 'repeatInterval': repeatInterval,
    };
  }

  factory UpdateReminderRequestDto.fromJson(Map<String, dynamic> json) {
    return UpdateReminderRequestDto(
      reminderId: json['reminderId'] as int? ?? 0,
      title: json['title'] as String?,
      remindAt: json['remindAt'] as String?,
      dueDate: json['dueDate'] as String?,
      dueTime: json['dueTime'] as String?,
      category: json['category'] as String?,
      status: json['status'] as String?,
      repeatInterval: json['repeatInterval'] as String?,
    );
  }
}
