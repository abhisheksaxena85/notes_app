import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/network/dto/response/item_status.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/views/screens/home/widgets/item_status_sheet.dart';

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

  // Left Status Strip Color
  Color stripColor;
  if (isCompleted) {
    stripColor = palette.success; // Dark Green
  } else if (isMissedOrRejected) {
    stripColor = palette.danger; // Danger Red
  } else {
    stripColor = palette.accent; // Primary Blue
  }

  final String title =
      reminder.title.trim().isNotEmpty ? reminder.title : "Untitled Reminder";
  final String category = (reminder.category != null && reminder.category!.trim().isNotEmpty)
      ? reminder.category!
      : "General";

  return Container(
    margin: EdgeInsets.only(bottom: 12.h),
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18.r),
      border: Border.all(color: palette.line, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: palette.brightness == Brightness.dark ? 0.2 : 0.03,
          ),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Status Strip
            Container(
              width: 5.w,
              color: stripColor,
            ),

            // Main Card Body
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onStatusSelected == null
                      ? null
                      : () async {
                          final selected = await showItemStatusSheet(
                            context,
                            currentStatus: reminder.status,
                            repeating: repeating && reminder.status == 'PENDING',
                          );
                          if (selected != null) onStatusSelected(selected);
                        },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row with Bell/Check, Title, Delete
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Status Toggle Icon Button
                            GestureDetector(
                              onTap: () {
                                // REM-05: a pending repeat is done for this
                                // occurrence only, then moves to the next.
                                final nextStatus = repeating && !isCompleted
                                    ? RepeatingChoice.doneToday
                                    : (isCompleted ? 'PENDING' : 'COMPLETED');
                                onStatusChange(nextStatus);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 24.r,
                                height: 24.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? palette.success
                                      : (isMissedOrRejected
                                          ? palette.danger.withValues(alpha: 0.15)
                                          : palette.accent.withValues(alpha: 0.12)),
                                  border: Border.all(
                                    color: isCompleted
                                        ? palette.success
                                        : (isMissedOrRejected
                                            ? palette.danger
                                            : palette.accent),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? AppIcons.icon(
                                          AppIcons.check,
                                          size: 14.sp,
                                          color: palette.onAccent,
                                        )
                                      : AppIcons.icon(
                                          AppIcons.reminder,
                                          size: 12.sp,
                                          color: isMissedOrRejected
                                              ? palette.danger
                                              : palette.accent,
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),

                            // Title
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  fontWeight: isCompleted
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: isCompleted
                                      ? palette.muted
                                      : palette.ink,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: palette.muted,
                                  decorationThickness: 2,
                                ),
                              ),
                            ),

                            if (onDelete != null) ...[
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: onDelete,
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: EdgeInsets.all(4.r),
                                  child: AppIcons.icon(
                                    AppIcons.delete,
                                    size: 18.sp,
                                    color: palette.muted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 10.h),

                        // Badges Row
                        Padding(
                          padding: EdgeInsets.only(left: 34.w),
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 6.h,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Date / Time Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.accentSoft,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppIcons.icon(
                                      AppIcons.clock,
                                      size: 11.sp,
                                      color: palette.accent,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      _formatReminderTime(reminder),
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: palette.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Category Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.line.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: palette.muted,
                                  ),
                                ),
                              ),

                              // Repeat Interval (if not NONE)
                              if (reminder.repeatInterval != 'NONE')
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    reminder.repeatInterval,
                                    style: GoogleFonts.inter(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w700,
                                      color: palette.accent,
                                    ),
                                  ),
                                ),

                              // REM-06: will this reminder alert?
                              if (alerts != null && alerts.isSupported && reminder.isUpcoming())
                                Tooltip(
                                  message: alerts.alertsOn
                                      ? 'Notification scheduled'
                                      : 'Notifications are off',
                                  child: alerts.alertsOn
                                      ? AppIcons.icon(AppIcons.reminder, size: 13.sp, color: palette.accent)
                                      : Icon(Icons.notifications_off_outlined, size: 13.sp, color: palette.muted),
                                ),

                              // REM-05: how the last occurrence went
                              if (repeating && _lastOutcomeLabel(reminder) != null)
                                Text(
                                  _lastOutcomeLabel(reminder)!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: reminder.lastOutcome == 'COMPLETED'
                                        ? palette.success
                                        : palette.danger,
                                  ),
                                ),

                              // Missed / Rejected Status Tag
                              if (isMissedOrRejected)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.danger.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.inter(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w800,
                                      color: palette.danger,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _formatReminderTime(ReminderItem reminder) {
  if (reminder.dueDate != null && reminder.dueDate!.isNotEmpty) {
    if (reminder.dueTime != null && reminder.dueTime!.isNotEmpty) {
      return "${reminder.dueDate} ${reminder.dueTime}";
    }
    return reminder.dueDate!;
  }
  if (reminder.remindAt.length >= 16) {
    return reminder.remindAt.replaceFirst('T', ' ').substring(0, 16);
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
