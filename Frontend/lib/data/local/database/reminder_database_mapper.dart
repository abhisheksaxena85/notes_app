import 'package:drift/drift.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';

class ReminderDatabaseMapper {
  static ReminderItem toReminderItem(CachedReminder reminder) {
    return ReminderItem(
      reminderId: reminder.serverId ?? -reminder.id,
      title: reminder.title,
      remindAt: reminder.remindAt,
      dueDate: reminder.dueDate,
      dueTime: reminder.dueTime,
      category: reminder.category,
      status: reminder.status,
      repeatInterval: reminder.repeatInterval,
      createdAt: reminder.createdAt,
      updatedAt: reminder.updatedAt,
      clientId: reminder.clientId,
      startAt: reminder.startAt,
      lastOutcome: reminder.lastOutcome,
      lastOutcomeAt: reminder.lastOutcomeAt,
      snoozedUntil: reminder.snoozedUntil,
    );
  }

  static CachedRemindersCompanion fromReminderItem(int userId, ReminderItem reminder) {
    return CachedRemindersCompanion.insert(
      userId: userId,
      serverId: reminder.reminderId != null && reminder.reminderId! > 0
          ? Value(reminder.reminderId)
          : const Value.absent(),
      title: reminder.title,
      remindAt: reminder.remindAt,
      dueDate: Value(reminder.dueDate),
      dueTime: Value(reminder.dueTime),
      category: Value(reminder.category ?? 'General'),
      status: Value(reminder.status),
      repeatInterval: Value(reminder.repeatInterval),
      createdAt: Value(reminder.createdAt),
      updatedAt: Value(reminder.updatedAt),
      isPending: const Value(false),
      clientId: Value(reminder.clientId),
      // Servers before REM-07 send no startAt: the series starts at remindAt.
      startAt: Value(reminder.startAt ?? reminder.remindAt),
      lastOutcome: Value(reminder.lastOutcome),
      lastOutcomeAt: Value(reminder.lastOutcomeAt),
      // snoozedUntil is local only: absent here, so a refresh keeps it.
    );
  }
}
