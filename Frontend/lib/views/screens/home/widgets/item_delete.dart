import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/widgets/confirm_dialog.dart';

/// FIX-01: asks first, then deletes the task (locally at once, the server
/// delete is queued) and says so. True when it was deleted.
Future<bool> confirmAndDeleteTask(
  BuildContext context,
  WidgetRef ref,
  TaskItem task,
) async {
  final id = task.taskId;
  if (id == null) return false;
  final tasks = ref.read(taskController.notifier);
  final messenger = ScaffoldMessenger.of(context);
  if (!await confirmDelete(context, kind: 'task', itemTitle: task.title)) {
    return false;
  }
  return _run(messenger, 'task', () => tasks.deleteTask(id));
}

/// Same as [confirmAndDeleteTask], for a reminder. A repeating one warns that
/// all future reminders stop.
Future<bool> confirmAndDeleteReminder(
  BuildContext context,
  WidgetRef ref,
  ReminderItem reminder,
) async {
  final id = reminder.reminderId;
  if (id == null) return false;
  final reminders = ref.read(reminderController.notifier);
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await confirmDelete(
    context,
    kind: 'reminder',
    itemTitle: reminder.title,
    repeating: reminder.repeatInterval != 'NONE',
  );
  if (!confirmed) return false;
  return _run(messenger, 'reminder', () => reminders.deleteReminder(id));
}

Future<bool> _run(
  ScaffoldMessengerState messenger,
  String kind,
  Future<void> Function() delete,
) async {
  try {
    await delete();
  } catch (e, st) {
    log('Delete $kind failed: $e', stackTrace: st);
    if (messenger.mounted) messenger.showSnackBar(failedSnackBar(userMessage(e)));
    return false;
  }
  if (messenger.mounted) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(deletedSnackBar(kind));
  }
  return true;
}
