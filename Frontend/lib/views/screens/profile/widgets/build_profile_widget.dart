import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/response/profile/profile_response_dto.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/home/widgets/workspace_header.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/account_sheet.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/notifications_sheet.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/data_backup_sheet.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/help_sheet.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/info_dialog.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/logout_sheet.dart';
import 'package:notes_app/views/widgets/daymark_card.dart';
import 'package:notes_app/views/widgets/icon_tile.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/section_header.dart';
import 'package:notes_app/views/widgets/sheet_scaffold.dart';

class BuildProfileWidget extends ConsumerWidget {
  final ProfileData profileData;

  const BuildProfileWidget({super.key, required this.profileData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.daymark;
    final noteCount = ref.watch(homeController).value?.notesData?.data?.length ?? 0;
    final tasks = ref.watch(taskController).value?.tasks ?? const [];
    final tasksDone = tasks.where((t) => t.effectiveStatus() == 'COMPLETED').length;
    final reminderCount = ref.watch(reminderController).value?.reminders.length ?? 0;
    final syncFailures = ref.watch(syncStatusController).value?.length ?? 0;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final userName = (profileData.name != null && profileData.name!.isNotEmpty)
        ? profileData.name!
        : "Daymark User";
    final userEmail =
        (profileData.email != null && profileData.email!.isNotEmpty)
        ? profileData.email!
        : "user@daymark.app";

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text("Profile", style: DaymarkText.title.copyWith(color: palette.ink)),
        const SizedBox(height: 18),

        // Profile card
        ProfileCard(
          avatar: UserAvatar(name: userName, size: 56),
          name: Text(
            userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DaymarkText.custom(17, FontWeight.w600).copyWith(color: palette.ink),
          ),
          email: Text(
            userEmail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DaymarkText.custom(13, FontWeight.w400).copyWith(color: palette.muted),
          ),
          action: ProfileEditButton(
            onPressed: () => showAccountDetailsSheet(context, ref, profileData),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _stat(palette, noteCount, "Notes")),
            const SizedBox(width: 8),
            Expanded(child: _stat(palette, tasksDone, "Tasks done")),
            const SizedBox(width: 8),
            Expanded(child: _stat(palette, reminderCount, "Reminders")),
          ],
        ),
        const SizedBox(height: 22),

        const OverlineLabel("Preferences"),
        const SizedBox(height: 8),
        SettingsGroup(
          children: [
            SettingsRow(
              icon: isDark ? AppIcons.darkMode : AppIcons.lightMode,
              title: "Appearance",
              value: Text(isDark ? "Dark" : "Light", style: _valueStyle(palette)),
              onTap: () => _showAppearanceSheet(context, ref, themeMode),
            ),
            // Hidden where the OS has no notifications (web, Windows, Linux)
            if (getIt<NotificationService>().isSupported)
              SettingsRow(
                icon: AppIcons.reminder,
                title: "Notifications",
                value: ValueListenableBuilder<NotificationStatus>(
                  valueListenable: getIt<NotificationPermissionService>().status,
                  builder: (context, status, _) => Text(
                    status.alertsOn ? "On" : "Off",
                    style: _valueStyle(palette).copyWith(
                      color: status.alertsOn ? palette.accent : palette.muted,
                    ),
                  ),
                ),
                onTap: () => showNotificationsSheet(context),
              ),
          ],
        ),
        const SizedBox(height: 22),

        const OverlineLabel("Data & support"),
        const SizedBox(height: 8),
        SettingsGroup(
          children: [
            SettingsRow(
              icon: AppIcons.backup,
              title: "Data & backup",
              value: Text(
                syncFailures == 0 ? "Synced" : "$syncFailures not synced",
                style: _valueStyle(palette).copyWith(
                  color: syncFailures == 0 ? palette.muted : palette.danger,
                ),
              ),
              onTap: () => showDataBackupSheet(context, ref),
            ),
            SettingsRow(
              icon: AppIcons.privacy,
              title: "Privacy & security",
              onTap: () => showInfoDialog(
                context,
                "Privacy & Security",
                "Your notes are synchronized with your personal MySQL account over HTTPS and cached locally in an encrypted Drift SQLite database.\n\nLogging out clears all user-scoped data from memory.",
              ),
            ),
            SettingsRow(
              icon: AppIcons.help,
              title: "Help & FAQ",
              onTap: () => showHelpSheet(context),
            ),
            SettingsRow(
              icon: AppIcons.info,
              title: "About Daymark",
              value: Text("v1.0.0", style: _valueStyle(palette)),
              onTap: () => showInfoDialog(
                context,
                "About Daymark",
                "Daymark Notes App v1.0.0\nCrafted with clean typography, dual theme tokens, and calm interface ergonomics.",
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        OutlineButton(
          label: "Sign out",
          icon: AppIcons.signOut,
          color: palette.danger,
          borderColor: palette.dangerBorder,
          onPressed: () => confirmLogout(context),
        ),
      ],
    );
  }

  static TextStyle _valueStyle(DaymarkPalette palette) =>
      DaymarkText.custom(14, FontWeight.w400).copyWith(color: palette.muted);

  Widget _stat(DaymarkPalette palette, int value, String label) => StatCard(
        value: Text(
          "$value",
          style: DaymarkText.custom(16, FontWeight.w600).copyWith(color: palette.ink),
        ),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DaymarkText.custom(12, FontWeight.w400).copyWith(color: palette.muted),
        ),
      );

  /// Appearance: Light or Dark.
  void _showAppearanceSheet(BuildContext context, WidgetRef ref, ThemeMode current) {
    final palette = context.daymark;
    showDaymarkSheet<void>(
      context,
      builder: (sheetContext) => SheetScaffold(
        title: "Appearance",
        child: Column(
          children: [
            for (final (mode, label, icon) in const [
              (ThemeMode.light, "Light", AppIcons.lightMode),
              (ThemeMode.dark, "Dark", AppIcons.darkMode),
            ])
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ref.read(themeModeProvider.notifier).setTheme(mode);
                  Navigator.pop(sheetContext);
                },
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      IconTile(icon: icon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: DaymarkText.custom(14.5, FontWeight.w500).copyWith(color: palette.ink),
                        ),
                      ),
                      if (current == mode)
                        AppIcons.icon(AppIcons.check, size: 18, color: palette.accent),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The profile card: avatar, name, email and an action button. Slots are
/// widgets so the loading state can shimmer them.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.avatar,
    required this.name,
    required this.email,
    required this.action,
  });

  final Widget avatar;
  final Widget name;
  final Widget email;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return DaymarkCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [name, const SizedBox(height: 3), email],
            ),
          ),
          const SizedBox(width: 10),
          action,
        ],
      ),
    );
  }
}

/// The 40 px outlined edit button on the profile card.
class ProfileEditButton extends StatelessWidget {
  const ProfileEditButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Account details',
      icon: AppIcons.icon(AppIcons.edit, size: 18, color: palette.inkSecondary),
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 40),
        minimumSize: const Size(40, 40),
        side: BorderSide(color: palette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// A grouped settings card with dividers between rows.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return DaymarkCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: 58, color: palette.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A 52 px settings row: 32 px icon tile, label, value and chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  final String icon;
  final String title;
  final Widget? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              IconTile(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DaymarkText.custom(14.5, FontWeight.w500).copyWith(color: palette.ink),
                ),
              ),
              if (value != null) ...[const SizedBox(width: 8), value!],
              const SizedBox(width: 6),
              AppIcons.icon(AppIcons.forward, size: 18, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildProfileWidget({
  required ProfileData profileData,
}) {
  return BuildProfileWidget(profileData: profileData);
}
