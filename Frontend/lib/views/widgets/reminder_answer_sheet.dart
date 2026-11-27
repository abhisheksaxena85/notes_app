import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/icon_tile.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/sheet_scaffold.dart';

/// Payloads of tapped reminder notifications waiting for the Workspace to
/// ask "Did you complete it?" (REM-04). Set from the notification callback
/// or the cold-start launch details; the dashboard consumes it once it is
/// on screen (so after the splash and login on a cold start).
final reminderPromptRequests = ValueNotifier<String?>(null);

/// Main isolate: the user tapped a notification, or one of its buttons
/// (iOS can deliver those here while the app runs). Body taps go to the
/// in-app prompt; buttons are answered right away with an Undo snackbar.
void routeNotificationResponse(
  NotificationResponse response, {
  required ReminderActionHandler Function() handler,
  required GlobalKey<ScaffoldMessengerState> messenger,
}) {
  final action = response.actionId;
  if (action == null || action.isEmpty) {
    reminderPromptRequests.value = response.payload;
    return;
  }
  unawaited(() async {
    final actions = handler();
    final result = await actions.handle(action, response.payload);
    final state = messenger.currentState;
    if (state != null) showReminderAnswerSnackBar(state, actions, result);
  }());
}

/// Shows the "Did you complete it?" sheet for a tapped notification and
/// applies the answer. Does nothing for a deleted reminder or one of a user
/// who has signed out.
Future<void> promptForReminder(
  BuildContext context,
  ReminderActionHandler handler,
  String payload,
) async {
  final opened = await handler.handle(null, payload);
  final reminder = opened.before;
  if (opened.outcome != ReminderActionOutcome.openPrompt || reminder == null) return;
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  if (reminder.status != 'PENDING') {
    messenger.showSnackBar(SnackBar(
      content: Text("'${reminder.title}' is already marked ${reminder.status.toLowerCase()}."),
    ));
    return;
  }
  final action = await showReminderAnswerSheet(
    context,
    reminder.title,
    meta: reminderAnswerMeta(
      context,
      remindAt: reminder.remindAt,
      repeatInterval: reminder.repeatInterval,
    ),
  );
  if (action == null) return;
  final result = await handler.handle(action, payload);
  showReminderAnswerSnackBar(messenger, handler, result);
}

/// "Did you {title}?" with [meta] ("Due 6:00 PM · Repeats daily") and
/// [Done] [Not done] [Snooze 10 min]. Returns the chosen [ReminderActions]
/// id, or null if dismissed.
Future<String?> showReminderAnswerSheet(
  BuildContext context,
  String title, {
  String? meta,
}) {
  final palette = context.daymark;
  return showDaymarkSheet<String>(
    context,
    builder: (sheetContext) => SheetScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
            icon: AppIcons.reminder,
            size: 48,
            radius: 15,
            iconSize: 22,
            background: palette.accentSoft,
            color: palette.accent,
          ),
          const SizedBox(height: 14),
          Text(
            reminderQuestion(title),
            style: DaymarkText.custom(19, FontWeight.w600, letterSpacing: -0.3)
                .copyWith(color: palette.ink),
          ),
          if (meta != null && meta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(meta, style: DaymarkText.meta.copyWith(color: palette.muted)),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Done',
            icon: AppIcons.check,
            onPressed: () => Navigator.of(sheetContext).pop(ReminderActions.done),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlineButton(
                  label: 'Not done',
                  onPressed: () => Navigator.of(sheetContext).pop(ReminderActions.notDone),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlineButton(
                  label: 'Snooze 10 min',
                  icon: AppIcons.snooze,
                  onPressed: () => Navigator.of(sheetContext).pop(ReminderActions.snooze),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// "Did you take pills?" from "Take pills"; keeps a leading acronym or
/// name ("Call NASA", "iPhone") as typed.
String reminderQuestion(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return 'Did you complete it?';
  final first = trimmed.split(RegExp(r'\s+')).first;
  final keepCase = first.length > 1 && first.substring(1) != first.substring(1).toLowerCase();
  final text = keepCase ? trimmed : trimmed[0].toLowerCase() + trimmed.substring(1);
  return 'Did you $text?';
}

/// "Due 6:00 PM · Repeats daily" for the in-app sheet.
String reminderAnswerMeta(BuildContext context, {required String remindAt, required String repeatInterval}) {
  final at = parseWallClock(remindAt);
  final use24h = MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false;
  return [
    if (at != null) 'Due ${formatDue(at, use24h: use24h)}',
    ?repeatLabel(repeatInterval),
  ].join(' · ');
}

/// "Marked done ✓ — Undo" after an answer given in the app.
void showReminderAnswerSnackBar(
  ScaffoldMessengerState messenger,
  ReminderActionHandler handler,
  ReminderActionResult result,
) {
  final message = switch ((result.outcome, result.actionId)) {
    (ReminderActionOutcome.answered, ReminderActions.done) => 'Marked done ✓',
    (ReminderActionOutcome.answered, _) => 'Marked as missed',
    (ReminderActionOutcome.snoozed, _) => 'Snoozed for 10 minutes',
    (ReminderActionOutcome.failed, _) => "Couldn't save your answer. Please try again.",
    _ => null,
  };
  if (message == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      action: result.outcome == ReminderActionOutcome.answered
          ? SnackBarAction(label: 'Undo', onPressed: () => unawaited(handler.undo(result)))
          : null,
    ));
}
