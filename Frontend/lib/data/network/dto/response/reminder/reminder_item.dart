import 'package:notes_app/data/network/dto/response/item_status.dart';

class ReminderItem {
  final int? reminderId;
  final String title;
  final String remindAt;
  final String? dueDate;
  final String? dueTime;
  final String? category;
  final String status; // PENDING, COMPLETED, REJECTED, MISSED
  final String repeatInterval; // NONE, DAILY, WEEKLY, MONTHLY
  final String? createdAt;
  final String? updatedAt;
  /// FE-03 idempotency key the item was created with (null for old items).
  final String? clientId;

  ReminderItem({
    this.reminderId,
    required this.title,
    required this.remindAt,
    this.dueDate,
    this.dueTime,
    this.category,
    this.status = 'PENDING',
    this.repeatInterval = 'NONE',
    this.createdAt,
    this.updatedAt,
    this.clientId,
  });

  /// Status to render: an overdue one-off PENDING reminder is shown as MISSED.
  /// Repeating reminders recur, so they are never considered missed.
  String effectiveStatus([DateTime? now]) {
    if (repeatInterval != 'NONE') return status;
    final due = ItemStatus.dueMoment(dueDate, dueTime) ??
        ItemStatus.dueMoment(
          remindAt,
          remindAt.length >= 16 ? remindAt.substring(11, 16) : null,
        );
    return ItemStatus.effective(status, due, now ?? DateTime.now());
  }

  /// Pending and still to come: a notification is (or should be) scheduled.
  /// Repeating reminders always have a next occurrence.
  bool isUpcoming([DateTime? now]) {
    if (status != ItemStatus.pending) return false;
    if (repeatInterval != 'NONE') return true;
    return effectiveStatus(now) == ItemStatus.pending;
  }

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['reminderId'] ?? json['id'];
    int? parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId);
    }

    final remindAtStr = (json['remindAt'] ?? '').toString();
    var dueDateStr = json['dueDate']?.toString();
    if ((dueDateStr == null || dueDateStr.isEmpty) && remindAtStr.length >= 10) {
      dueDateStr = remindAtStr.substring(0, 10);
    }

    var dueTimeStr = json['dueTime']?.toString();
    if ((dueTimeStr == null || dueTimeStr.isEmpty) && remindAtStr.length >= 16) {
      dueTimeStr = remindAtStr.substring(11, 16);
    }

    return ReminderItem(
      reminderId: parsedId,
      title: (json['title'] ?? '').toString(),
      remindAt: remindAtStr,
      dueDate: dueDateStr,
      dueTime: dueTimeStr,
      category: json['category']?.toString() ?? 'General',
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      repeatInterval: json['repeatInterval']?.toString().toUpperCase() ?? 'NONE',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      clientId: json['clientId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (reminderId != null) 'reminderId': reminderId,
      'title': title,
      'remindAt': remindAt,
      if (dueDate != null) 'dueDate': dueDate,
      if (dueTime != null) 'dueTime': dueTime,
      if (category != null) 'category': category,
      'status': status,
      'repeatInterval': repeatInterval,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (clientId != null) 'clientId': clientId,
    };
  }

  ReminderItem copyWith({
    int? reminderId,
    String? title,
    String? remindAt,
    String? dueDate,
    String? dueTime,
    String? category,
    String? status,
    String? repeatInterval,
    String? createdAt,
    String? updatedAt,
    String? clientId,
  }) {
    return ReminderItem(
      reminderId: reminderId ?? this.reminderId,
      title: title ?? this.title,
      remindAt: remindAt ?? this.remindAt,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      category: category ?? this.category,
      status: status ?? this.status,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientId: clientId ?? this.clientId,
    );
  }
}
