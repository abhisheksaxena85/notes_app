import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/services/digest_scheduler.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/notification_permission_prompt.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/sheet_scaffold.dart';

/// Profile → Notifications: alert status, daily reminder and weekly summary.
void showNotificationsSheet(BuildContext context) {
  final palette = context.daymark;
  final digests = getIt<DigestScheduler>();
  bool isDaily = digests.dailyEnabled;
  TimeOfDay reminderTime = digests.dailyTime;
  bool isWeekly = digests.weeklyEnabled;
  final permissions = getIt<NotificationPermissionService>();
  permissions.refresh();

  showDaymarkSheet<void>(
    context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final formattedTime = DisplayFormat.time(reminderTime.hour, reminderTime.minute);

          Widget divider() => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, thickness: 1, color: palette.divider),
              );

          Widget switchRow({
            required String title,
            required String subtitle,
            required bool value,
            required ValueChanged<bool> onChanged,
          }) {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DaymarkText.custom(14.5, FontWeight.w500).copyWith(color: palette.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: DaymarkText.meta.copyWith(color: palette.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(value: value, onChanged: onChanged),
              ],
            );
          }

          return SheetScaffold(
            title: "Notifications",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Managed locally on your device without backend tracking.",
                  style: DaymarkText.preview.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 12),
                // REM-02: whether reminders will alert, and how to fix it.
                NotificationStatusRow(permissions: permissions),
                divider(),
                switchRow(
                  title: "Daily writing reminder",
                  subtitle: "Scheduled for $formattedTime",
                  value: isDaily,
                  onChanged: (val) async {
                    // REM-08: only on if notifications are allowed.
                    if (val && !await ensureNotificationsAllowed(context, permissions)) return;
                    setModalState(() => isDaily = val);
                    await digests.setDaily(val, time: reminderTime);
                  },
                ),
                if (isDaily) ...[
                  const SizedBox(height: 10),
                  OutlineButton(
                    label: "Change time ($formattedTime)",
                    icon: AppIcons.clock,
                    color: palette.accent,
                    height: 44,
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
                  ),
                ],
                divider(),
                switchRow(
                  title: "Weekly activity summary",
                  subtitle: "Sundays at 6:00 PM",
                  value: isWeekly,
                  onChanged: (val) async {
                    if (val && !await ensureNotificationsAllowed(context, permissions)) return;
                    setModalState(() => isWeekly = val);
                    await digests.setWeekly(val);
                  },
                ),
                if (kDebugMode && getIt<NotificationService>().isSupported) ...[
                  divider(),
                  // Debug builds only: checks the plugin setup end to end.
                  OutlineButton(
                    label: "Test notification",
                    icon: AppIcons.reminder,
                    color: palette.accent,
                    height: 44,
                    onPressed: () => getIt<NotificationService>().showNow(
                      id: 999999,
                      title: 'Test notification',
                      body: 'Reminders will look like this.',
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}
