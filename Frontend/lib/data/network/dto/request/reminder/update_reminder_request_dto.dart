class UpdateReminderRequestDto {
  final int reminderId;
  final String? title;
  final String? remindAt;
  final String? dueDate;
  final String? dueTime;
  final String? category;
  final String? status;
  final String? repeatInterval;

  /// REM-05: the series anchor. Sent with every remindAt change the app
  /// makes, so the server doesn't re-anchor a series it only advanced.
  final String? startAt;

  /// REM-05: answer to the last occurrence (catch-up of missed repeats).
  final String? lastOutcome;
  final String? lastOutcomeAt;

  UpdateReminderRequestDto({
    required this.reminderId,
    this.title,
    this.remindAt,
    this.dueDate,
    this.dueTime,
    this.category,
    this.status,
    this.repeatInterval,
    this.startAt,
    this.lastOutcome,
    this.lastOutcomeAt,
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
      if (startAt != null) 'startAt': startAt,
      if (lastOutcome != null) 'lastOutcome': lastOutcome,
      if (lastOutcomeAt != null) 'lastOutcomeAt': lastOutcomeAt,
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
      startAt: json['startAt'] as String?,
      lastOutcome: json['lastOutcome'] as String?,
      lastOutcomeAt: json['lastOutcomeAt'] as String?,
    );
  }
}
