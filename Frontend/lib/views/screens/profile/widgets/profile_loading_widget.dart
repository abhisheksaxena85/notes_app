import 'package:flutter/material.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/screens/home/widgets/workspace_header.dart';
import 'package:notes_app/views/screens/profile/widgets/build_profile_widget.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/section_header.dart';
import 'package:notes_app/views/widgets/skeleton/skeleton.dart';

/// The Profile while it loads (design/README.md §7): the title, group labels
/// and setting labels are real; the avatar, name, email, edit button, stats
/// and setting values shimmer. Sign out is shown faded.
class ProfileLoadingWidget extends StatelessWidget {
  const ProfileLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    Widget value(double width) => SkeletonBox(width: width, height: 11, radius: 5.5);
    Widget stat(double labelWidth) => Expanded(
          child: StatCard(
            value: const SizedBox(
              height: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SkeletonBox(width: 24, height: 14, radius: 7),
              ),
            ),
            label: SizedBox(
              height: 15,
              child: Center(child: SkeletonLine(widthFactor: labelWidth, height: 10)),
            ),
          ),
        );

    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text("Profile", style: DaymarkText.title.copyWith(color: palette.ink)),
          const SizedBox(height: 18),
          const ProfileCard(
            avatar: SkeletonCircle(size: 56),
            name: SizedBox(height: 22, child: Center(child: SkeletonLine(widthFactor: 0.6, height: 14))),
            email: SizedBox(height: 16, child: Center(child: SkeletonLine(widthFactor: 0.8, height: 10))),
            action: SkeletonBox(width: 40, height: 40, radius: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              stat(0.5),
              const SizedBox(width: 8),
              stat(0.75),
              const SizedBox(width: 8),
              stat(0.65),
            ],
          ),
          const SizedBox(height: 22),
          const OverlineLabel("Preferences"),
          const SizedBox(height: 8),
          SettingsGroup(
            children: [
              SettingsRow(icon: AppIcons.lightMode, title: "Appearance", value: value(38)),
              if (getIt<NotificationService>().isSupported)
                SettingsRow(icon: AppIcons.reminder, title: "Notifications", value: value(24)),
            ],
          ),
          const SizedBox(height: 22),
          const OverlineLabel("Data & support"),
          const SizedBox(height: 8),
          SettingsGroup(
            children: [
              SettingsRow(icon: AppIcons.backup, title: "Data & backup", value: value(46)),
              const SettingsRow(icon: AppIcons.privacy, title: "Privacy & security"),
              const SettingsRow(icon: AppIcons.help, title: "Help & FAQ"),
              SettingsRow(icon: AppIcons.info, title: "About Daymark", value: value(34)),
            ],
          ),
          const SizedBox(height: 24),
          Opacity(
            opacity: 0.45,
            child: OutlineButton(
              label: "Sign out",
              icon: AppIcons.signOut,
              color: palette.danger,
              borderColor: palette.dangerBorder,
              onPressed: null,
            ),
          ),
        ],
      ),
    );
  }
}

Widget profileLoadingWidget() => const ProfileLoadingWidget();
