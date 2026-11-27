import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';

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
  final action = await showReminderAnswerSheet(context, reminder.title);
  if (action == null) return;
  final result = await handler.handle(action, payload);
  showReminderAnswerSnackBar(messenger, handler, result);
}

/// "Did you complete '<title>'?" [Done] [Not done] [Snooze 10 min].
/// Returns the chosen [ReminderActions] id, or null if dismissed.
Future<String?> showReminderAnswerSheet(BuildContext context, String title) {
  final palette = context.daymark;
  final isDark = palette.brightness == Brightness.dark;
  Widget button(BuildContext sheetContext, String action, String label, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: SizedBox(
        width: double.infinity,
        height: 46.h,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.of(sheetContext).pop(action),
          icon: Icon(icon, color: color, size: 18.sp),
          label: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: palette.ink),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: palette.line),
            backgroundColor: isDark ? palette.background : palette.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Did you complete '$title'?",
              style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: palette.ink),
            ),
            SizedBox(height: 16.h),
            button(sheetContext, ReminderActions.done, 'Done', Icons.check_circle_rounded, palette.success),
            button(sheetContext, ReminderActions.notDone, 'Not done', Icons.cancel_outlined,
                palette.danger),
            button(sheetContext, ReminderActions.snooze, 'Snooze 10 min', Icons.snooze_rounded,
                palette.accent),
          ],
        ),
      ),
    ),
  );
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
