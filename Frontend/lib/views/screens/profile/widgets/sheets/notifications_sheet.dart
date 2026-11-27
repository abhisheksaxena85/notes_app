import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/services/digest_scheduler.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/views/widgets/notification_permission_prompt.dart';

/// Profile → Notifications: alert status, daily reminder and weekly summary.
void showNotificationsSheet(BuildContext context) {
  final palette = context.daymark;
  final digests = getIt<DigestScheduler>();
  bool isDaily = digests.dailyEnabled;
  TimeOfDay reminderTime = digests.dailyTime;
  bool isWeekly = digests.weeklyEnabled;
  final permissions = getIt<NotificationPermissionService>();
  permissions.refresh();

  showModalBottomSheet(
    context: context,
    backgroundColor: palette.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final period = reminderTime.period == DayPeriod.am ? "AM" : "PM";
          final hour = reminderTime.hourOfPeriod == 0 ? 12 : reminderTime.hourOfPeriod;
          final minuteStr = reminderTime.minute.toString().padLeft(2, '0');
          final formattedTime = "$hour:$minuteStr $period";

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: palette.line,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Text(
                  "Local Reminders & Notifications",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  "Managed locally on your device without backend tracking.",
                  style: GoogleFonts.inter(fontSize: 12.sp, color: palette.muted),
                ),
                SizedBox(height: 14.h),
                // REM-02: whether reminders will alert, and how to fix it.
                NotificationStatusRow(permissions: permissions),
                Divider(color: palette.line, height: 24.h),
                // Daily Reminder Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Daily Writing Reminder",
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "Scheduled for $formattedTime",
                          style: GoogleFonts.inter(fontSize: 11.sp, color: palette.muted),
                        ),
                      ],
                    ),
                    Switch(
                      value: isDaily,
                      activeThumbColor: palette.accent,
                      onChanged: (val) async {
                        // REM-08: only on if notifications are allowed.
                        if (val && !await ensureNotificationsAllowed(context, permissions)) return;
                        setModalState(() => isDaily = val);
                        await digests.setDaily(val, time: reminderTime);
                      },
                    ),
                  ],
                ),
                if (isDaily) ...[
                  SizedBox(height: 8.h),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: reminderTime,
                      );
                      if (picked != null) {
                        setModalState(() => reminderTime = picked);
                        await digests.setDaily(true, time: picked);
                      }
                    },
                    icon: Icon(Icons.access_time_rounded, size: 16.sp, color: palette.accent),
                    label: Text(
                      "Change Time ($formattedTime)",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ],
                Divider(color: palette.line, height: 24.h),
                // Weekly Summary Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Weekly Activity Summary",
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "Sundays at 6:00 PM",
                          style: GoogleFonts.inter(fontSize: 11.sp, color: palette.muted),
                        ),
                      ],
                    ),
                    Switch(
                      value: isWeekly,
                      activeThumbColor: palette.accent,
                      onChanged: (val) async {
                        if (val && !await ensureNotificationsAllowed(context, permissions)) return;
                        setModalState(() => isWeekly = val);
                        await digests.setWeekly(val);
                      },
                    ),
                  ],
                ),
                if (kDebugMode && getIt<NotificationService>().isSupported) ...[
                  Divider(color: palette.line, height: 24.h),
                  // Debug builds only: checks the plugin setup end to end.
                  OutlinedButton.icon(
                    onPressed: () => getIt<NotificationService>().showNow(
                      id: 999999,
                      title: 'Test notification',
                      body: 'Reminders will look like this.',
                    ),
                    icon: Icon(Icons.notifications_active_outlined, size: 16.sp, color: palette.accent),
                    label: Text(
                      "Test notification",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ],
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      );
    },
  );
}
