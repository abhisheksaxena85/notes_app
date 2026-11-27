import 'package:flutter/material.dart';
import 'package:notes_app/data/network/dto/response/item_status.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/screens/home/widgets/item_status_sheet.dart';
import 'package:notes_app/views/widgets/daymark_card.dart';
import 'package:notes_app/views/widgets/status_pill.dart';

/// A reminder on the Workspace (design/README.md §6). The leading 36 px bell
/// tile is `accentSoft`/`accent` when pending, `dangerSoft`/`danger` when
/// missed and `successSoft`/`success` when completed; tapping it answers the
/// reminder.
Widget reminderItemCard({
  required BuildContext context,
  required ReminderItem reminder,
  required ValueChanged<String> onStatusChange,
  VoidCallback? onTap,
  VoidCallback? onDelete,
  ValueChanged<String>? onStatusSelected,
  NotificationStatus? alerts,
}) {
  final palette = context.daymark;
  final String status = reminder.effectiveStatus();
  final bool isCompleted = status == 'COMPLETED';
  final bool isMissedOrRejected = status == 'MISSED' || status == 'REJECTED';
  final bool repeating = reminder.repeatInterval != 'NONE';

  final String title =
      reminder.title.trim().isNotEmpty ? reminder.title : "Untitled Reminder";
  final String category = (reminder.category != null && reminder.category!.trim().isNotEmpty)
      ? reminder.category!
      : "General";

  final Color tileFill;
  final Color tileIcon;
  if (isCompleted) {
    tileFill = palette.successSoft;
    tileIcon = palette.success;
  } else if (isMissedOrRejected) {
    tileFill = palette.dangerSoft;
    tileIcon = palette.danger;
  } else {
    tileFill = palette.accentSoft;
    tileIcon = palette.accent;
  }

  final due = DisplayFormat.day(reminder.dueDate);
  final bool dueToday = due != null && DisplayFormat.sameDay(due, DateTime.now());
  final metaStyle = DaymarkText.meta.copyWith(color: palette.muted);
  const dot = TextSpan(text: '\u00A0\u00A0·  ');
  final lastOutcome = repeating ? _lastOutcomeLabel(reminder) : null;

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DaymarkCard(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      onTap: onTap,
      onLongPress: onStatusSelected == null
          ? null
          : () async {
              final selected = await showItemStatusSheet(
                context,
                currentStatus: reminder.status,
                repeating: repeating && reminder.status == 'PENDING',
                canDelete: onDelete != null,
              );
              if (selected == deleteItemChoice) {
                onDelete?.call();
              } else if (selected != null) {
                onStatusSelected(selected);
              }
            },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 36 px status tile in a 44+ px touch target.
          Semantics(
            button: true,
            label: isCompleted ? 'Mark as not done' : 'Mark as done',
            child: GestureDetector(
              onTap: () {
                // REM-05: a pending repeat is done for this
                // occurrence only, then moves to the next.
                final nextStatus = repeating && !isCompleted
                    ? RepeatingChoice.doneToday
                    : (isCompleted ? 'PENDING' : 'COMPLETED');
                onStatusChange(nextStatus);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tileFill,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: AppIcons.icon(
                      isCompleted ? AppIcons.check : AppIcons.reminder,
                      size: 18,
                      color: tileIcon,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DaymarkText.bodyStrong.copyWith(
                            color: isCompleted ? palette.muted : palette.ink,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: palette.muted,
                          ),
                        ),
                      ),
                      if (isMissedOrRejected) ...[
                        const SizedBox(width: 8),
                        StatusPill(StatusPill.labelFor(status)),
                      ] else if (dueToday && !isCompleted) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            'Today',
                            style: DaymarkText.custom(12.5, FontWeight.w500).copyWith(color: palette.accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text.rich(
                    TextSpan(
                      style: metaStyle,
                      children: [
                        _iconSpan(AppIcons.clock, palette.muted),
                        TextSpan(text: _formatReminderTime(reminder)),
                        dot,
                        TextSpan(text: category),
                        if (repeating) ...[
                          dot,
                          _iconSpan(AppIcons.repeat, palette.muted),
                          TextSpan(text: StatusPill.labelFor(reminder.repeatInterval)),
                        ],
                        // REM-06: will this reminder alert?
                        if (alerts != null && alerts.isSupported && reminder.isUpcoming())
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Tooltip(
                                message: alerts.alertsOn
                                    ? 'Notification scheduled'
                                    : 'Notifications are off',
                                child: alerts.alertsOn
                                    ? AppIcons.icon(AppIcons.reminder, size: 14, color: palette.accent)
                                    : Icon(Icons.notifications_off_outlined, size: 14, color: palette.muted),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // REM-05: how the last occurrence went
                  if (lastOutcome != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      lastOutcome,
                      style: DaymarkText.custom(12, FontWeight.w500).copyWith(
                        color: reminder.lastOutcome == 'COMPLETED'
                            ? palette.success
                            : palette.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (onDelete != null)
            CardIconButton(
              icon: AppIcons.icon(AppIcons.delete, size: 18, color: palette.muted),
              tooltip: 'Delete',
              onPressed: onDelete,
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    ),
  );
}

/// A 14 px icon inline with meta text.
InlineSpan _iconSpan(String icon, Color color) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.only(right: 5),
        child: AppIcons.icon(icon, size: 14, color: color),
      ),
    );

String _formatReminderTime(ReminderItem reminder) {
  if (reminder.dueDate != null && reminder.dueDate!.isNotEmpty) {
    return DisplayFormat.due(reminder.dueDate, reminder.dueTime);
  }
  if (reminder.remindAt.length >= 16) {
    return DisplayFormat.due(reminder.remindAt.substring(0, 10), reminder.remindAt.substring(11, 16));
  }
  return reminder.remindAt;
}

/// "Last: done ✓" / "Last: missed (Nov 25)" for a repeating reminder.
String? _lastOutcomeLabel(ReminderItem reminder) {
  final outcome = reminder.lastOutcome;
  if (outcome == null) return null;
  final at = parseWallClock(reminder.lastOutcomeAt);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final when = at == null ? '' : ' (${months[at.month - 1]} ${at.day})';
  return outcome == 'COMPLETED' ? 'Last: done ✓$when' : 'Last: missed$when';
}
