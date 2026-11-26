class CreateReminderRequestDto {
  final int userId;
  final String title;
  final String remindAt; // ISO-8601 string
  final String? dueDate;
  final String? dueTime;
  final String? category;
  final String? status;
  final String? repeatInterval;

  /// FE-03: idempotency key, so a retried create can't make a duplicate.
  final String? clientId;

  CreateReminderRequestDto({
    required this.userId,
    required this.title,
    required this.remindAt,
    this.dueDate,
    this.dueTime,
    this.category,
    this.status,
    this.repeatInterval,
    this.clientId,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'remindAt': remindAt,
      if (dueDate != null) 'dueDate': dueDate,
      if (dueTime != null) 'dueTime': dueTime,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (repeatInterval != null) 'repeatInterval': repeatInterval,
      if (clientId != null) 'clientId': clientId,
    };
  }

  factory CreateReminderRequestDto.fromJson(Map<String, dynamic> json) {
    return CreateReminderRequestDto(
      userId: json['userId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      remindAt: json['remindAt'] as String? ?? '',
      dueDate: json['dueDate'] as String?,
      dueTime: json['dueTime'] as String?,
      category: json['category'] as String?,
      status: json['status'] as String?,
      repeatInterval: json['repeatInterval'] as String?,
      clientId: json['clientId'] as String?,
    );
  }
}
