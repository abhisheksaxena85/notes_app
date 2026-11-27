import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';

/// REM-02: asks for notifications in context, after a reminder was saved.
///
/// Shows the Daymark pre-prompt only while the OS was never asked (and at
/// most once per 30 days after "Not now"), then the OS prompt, then on
/// Android the exact-alarm explainer if on-time delivery is off. Never
/// throws: the reminder is saved whatever the answer.
Future<void> maybeAskForNotifications(
  BuildContext context,
  NotificationPermissionService permissions,
) async {
  if (!permissions.notifications.isSupported) return;
  if (!await permissions.shouldShowPrePrompt()) return;
  if (!context.mounted) return;
  await permissions.markPrePromptShown();
  if (!context.mounted) return;

  final allow = await showNotificationPrePrompt(context);
  if (allow != true) return;
  final granted = await permissions.request();
  if (!granted || !context.mounted) return;
  if (!permissions.status.value.exactAllowed) {
    await showExactAlarmPrompt(context, permissions);
  }
}

/// "Get notified when it's time?" Returns true for [Allow notifications].
Future<bool?> showNotificationPrePrompt(BuildContext context) {
  final palette = context.daymark;
  final isDark = palette.brightness == Brightness.dark;
  return showModalBottomSheet<bool>(
    context: context,
    // Sized to its content, scrolling on short screens or with large fonts.
    isScrollControlled: true,
    backgroundColor: palette.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(color: palette.accentSoft, shape: BoxShape.circle),
              child: AppIcons.icon(AppIcons.reminder, color: palette.accent, size: 22.sp),
            ),
            SizedBox(height: 14.h),
            Text(
              "Get notified when it's time?",
              style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: palette.ink),
            ),
            SizedBox(height: 6.h),
            Text(
              'Daymark will alert you and you can mark it done right from the notification.',
              style: GoogleFonts.inter(fontSize: 13.sp, color: palette.muted, height: 1.4),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? palette.accent : palette.ink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
                child: Text(
                  'Allow notifications',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? palette.background : palette.surface,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text(
                  'Not now',
                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: palette.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Android 12+: explains exact alarms and opens the system setting.
Future<void> showExactAlarmPrompt(
  BuildContext context,
  NotificationPermissionService permissions,
) async {
  final palette = context.daymark;
  final open = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: palette.surface,
      title: Text(
        'On-time alerts',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: palette.ink),
      ),
      content: Text(
        'For on-time alerts, allow Daymark to set alarms. Without it, reminders may arrive a few minutes late.',
        style: GoogleFonts.inter(color: palette.muted, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Not now', style: GoogleFonts.inter(color: palette.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            'Open settings',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: palette.accent),
          ),
        ),
      ],
    ),
  );
  if (open == true) await permissions.requestExact();
}

/// REM-08: before turning on a digest. Asks if the OS can still ask;
/// otherwise explains and offers the OS settings. True if allowed.
Future<bool> ensureNotificationsAllowed(
  BuildContext context,
  NotificationPermissionService permissions,
) async {
  final status = await permissions.refresh();
  if (status.alertsOn) return true;
  if (status.permission != NotificationPermission.permanentlyDenied && await permissions.request()) {
    return true;
  }
  if (!context.mounted) return false;
  final palette = context.daymark;
  final open = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: palette.surface,
      title: Text(
        'Notifications are off',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: palette.ink),
      ),
      content: Text(
        'Daymark needs permission to send notifications for this. You can turn it on in Settings.',
        style: GoogleFonts.inter(color: palette.muted, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Not now', style: GoogleFonts.inter(color: palette.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            'Open settings',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: palette.accent),
          ),
        ),
      ],
    ),
  );
  if (open == true) await permissions.openSettings();
  return false;
}

/// The text of the notification status row in Profile → Notifications.
String notificationStatusLabel(NotificationStatus status) => switch (status.permission) {
  NotificationPermission.granted => status.exactAllowed ? 'On' : 'On, but may be late',
  NotificationPermission.permanentlyDenied => 'Off – open settings to enable',
  NotificationPermission.unsupported => 'Not available on this device',
  _ => 'Off – tap to enable',
};

/// Profile → Notifications: whether reminders will alert, with the action
/// that fixes it (OS prompt, OS settings, or the exact-alarm setting).
class NotificationStatusRow extends StatelessWidget {
  final NotificationPermissionService permissions;

  const NotificationStatusRow({super.key, required this.permissions});

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return ValueListenableBuilder<NotificationStatus>(
      valueListenable: permissions.status,
      builder: (context, status, _) {
        if (!status.isSupported) return const SizedBox.shrink();
        final ok = status.alertsOn && status.exactAllowed;
        final color = status.alertsOn ? (ok ? palette.accent : palette.muted) : palette.danger;
        return InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: ok ? null : permissions.enable,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Row(
              children: [
                status.alertsOn
                    ? AppIcons.icon(AppIcons.reminder, size: 20.sp, color: color)
                    : Icon(Icons.notifications_off_outlined, size: 20.sp, color: color),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminder alerts',
                        style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: palette.ink),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        notificationStatusLabel(status),
                        style: GoogleFonts.inter(fontSize: 11.sp, color: color),
                      ),
                      if (status.mayBeLate)
                        Text(
                          'Tap to allow alarms for on-time delivery.',
                          style: GoogleFonts.inter(fontSize: 11.sp, color: palette.muted),
                        ),
                    ],
                  ),
                ),
                if (!ok) AppIcons.icon(AppIcons.forward, color: palette.muted),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Workspace: "Reminders won't alert you" while there are upcoming reminders
/// and notifications are off. Dismissing hides it until the next app start.
class NotificationsOffBanner extends StatefulWidget {
  /// Shows the banner again after it was dismissed (tests).
  @visibleForTesting
  static void resetDismissed() => _NotificationsOffBannerState.resetDismissed();

  final NotificationPermissionService permissions;
  final bool hasUpcomingReminders;

  const NotificationsOffBanner({
    super.key,
    required this.permissions,
    required this.hasUpcomingReminders,
  });

  @override
  State<NotificationsOffBanner> createState() => _NotificationsOffBannerState();
}

class _NotificationsOffBannerState extends State<NotificationsOffBanner> {
  static bool _dismissed = false;

  @visibleForTesting
  static void resetDismissed() => _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return ValueListenableBuilder<NotificationStatus>(
      valueListenable: widget.permissions.status,
      builder: (context, status, _) {
        if (_dismissed || !widget.hasUpcomingReminders || !status.alertsOff) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 14.h),
          child: Material(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(14.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: widget.permissions.enable,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 6.h, 4.w, 6.h),
                child: Row(
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 18.sp, color: palette.accent),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "Reminders won't alert you — ",
                          style: GoogleFonts.inter(fontSize: 13.sp, color: palette.ink),
                          children: [
                            TextSpan(
                              text: 'Turn on notifications',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: palette.accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dismiss',
                      onPressed: () => setState(() => _dismissed = true),
                      icon: AppIcons.icon(AppIcons.close, size: 18.sp, color: palette.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
