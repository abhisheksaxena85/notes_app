import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/response/profile/profile_response_dto.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/account_sheet.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/notifications_sheet.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/data_backup_sheet.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/help_sheet.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/info_dialog.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/logout_sheet.dart';

class BuildProfileWidget extends ConsumerWidget {
  final ProfileData profileData;

  const BuildProfileWidget({super.key, required this.profileData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.daymark;
    final homeState = ref.watch(homeController);
    final noteCount = homeState.value?.notesData?.data?.length ?? 0;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final userName = (profileData.name != null && profileData.name!.isNotEmpty)
        ? profileData.name!
        : "Daymark User";
    final userEmail =
        (profileData.email != null && profileData.email!.isNotEmpty)
        ? profileData.email!
        : "user@daymark.app";
    final firstLetter =
        userName.isNotEmpty ? userName[0].toUpperCase() : "D";

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(
        top: 14.h,
        bottom: 90.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: YOUR SPACE / Profile
          Text(
            "YOUR SPACE",
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              color: palette.muted,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            "Profile",
            style: GoogleFonts.inter(
              fontSize: 31.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: palette.ink,
            ),
          ),
          SizedBox(height: 16.h),

          // User Card matching Figma (350x136, rx 22)
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: palette.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Column(
              children: [
                // Top user row: Avatar + Name/Email + Verified badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar circle
                    Container(
                      width: 52.r,
                      height: 52.r,
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          firstLetter,
                          style: GoogleFonts.inter(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: palette.accent,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            userEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Verified Badge circle
                    Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: AppIcons.icon(
                          AppIcons.check,
                          size: 15.sp,
                          color: palette.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Card Divider
                Divider(color: palette.line, height: 1),
                SizedBox(height: 12.h),

                // Bottom stats row: Note count + DEMO/ACTIVE pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AppIcons.icon(
                          AppIcons.workspace,
                          size: 15.sp,
                          color: palette.muted,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "$noteCount ${noteCount == 1 ? "note" : "notes"} saved on this device",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: palette.background,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        "ACTIVE USER",
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: palette.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // PREFERENCES Section Header
          Text(
            "PREFERENCES",
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: palette.muted,
            ),
          ),
          SizedBox(height: 10.h),

          // Preferences Group Container (radius 19, surface fill, line border)
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(19.r),
              border: Border.all(color: palette.line),
            ),
            child: Column(
              children: [
                // Item 1: Account Details
                _buildSettingsRow(
                  iconPath: AppIcons.profile,
                  title: "Account details",
                  subtitle: "Your profile information & settings",
                  palette: palette,
                  onTap: () => showAccountDetailsSheet(context, ref, profileData),
                ),
                _buildDivider(palette),

                // Item 2: Dark Theme (TOGGLE SWITCH)
                _buildDarkThemeRow(
                  isDark: isDark,
                  palette: palette,
                  onToggle: () {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
                _buildDivider(palette),

                // Item 3: App Preferences
                _buildSettingsRow(
                  iconPath: AppIcons.preferences,
                  title: "App preferences",
                  subtitle: "Appearance, theme, and reading options",
                  palette: palette,
                  onTap: () => showInfoDialog(
                    context,
                    "App Preferences",
                    "Dual light/dark themes are rendered dynamically from the Figma design tokens.\nTypography uses Google Fonts Inter.",
                  ),
                ),
                // Item 4: Notifications (hidden where the OS has none: web,
                // Windows, Linux)
                if (getIt<NotificationService>().isSupported) ...[
                  _buildDivider(palette),
                  _buildSettingsRow(
                    iconPath: AppIcons.reminder,
                    title: "Notifications",
                    subtitle: "Reminder alerts, daily reminder and weekly summary",
                    palette: palette,
                    onTap: () => showNotificationsSheet(context),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // DATA & SUPPORT Section Header
          Text(
            "DATA & SUPPORT",
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: palette.muted,
            ),
          ),
          SizedBox(height: 10.h),

          // Data Group Container
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(19.r),
              border: Border.all(color: palette.line),
            ),
            child: Column(
              children: [
                _buildSettingsRow(
                  iconPath: AppIcons.privacy,
                  title: "Privacy & security",
                  subtitle: "Understand how notes are stored",
                  palette: palette,
                  onTap: () => showInfoDialog(
                    context,
                    "Privacy & Security",
                    "Your notes are synchronized with your personal MySQL account over HTTPS and cached locally in an encrypted Drift SQLite database.\n\nLogging out clears all user-scoped data from memory.",
                  ),
                ),
                _buildDivider(palette),
                _buildSettingsRow(
                  iconPath: AppIcons.backup,
                  title: "Data & backup",
                  subtitle: "Export or import notes as CSV, TXT, or JSON",
                  palette: palette,
                  onTap: () => showDataBackupSheet(context, ref),
                ),
                _buildDivider(palette),
                _buildSettingsRow(
                  iconPath: AppIcons.help,
                  title: "Help & support",
                  subtitle: "FAQs and app documentation",
                  palette: palette,
                  onTap: () => showHelpSheet(context),
                ),
                _buildDivider(palette),
                _buildSettingsRow(
                  iconPath: AppIcons.info,
                  title: "About Daymark",
                  subtitle: "Version and design system",
                  palette: palette,
                  onTap: () => showInfoDialog(
                    context,
                    "About Daymark",
                    "Daymark Notes App v1.0.0\nCrafted with clean typography, dual theme tokens, and calm interface ergonomics.",
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Logout Action Button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton.icon(
              onPressed: () => confirmLogout(context),
              icon: AppIcons.icon(AppIcons.signOut, color: palette.danger, size: 18.sp),
              label: Text(
                "Sign Out",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: palette.danger,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: palette.danger.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Version Footer
          Center(
            child: Text(
              "DAYMARK  ·  VERSION 1.0.0",
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: palette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(DaymarkPalette palette) {
    return Padding(
      padding: EdgeInsets.only(left: 56.w, right: 16.w),
      child: Divider(color: palette.line, height: 1),
    );
  }

  Widget _buildSettingsRow({
    required String iconPath,
    required String title,
    required String subtitle,
    required DaymarkPalette palette,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 34.r,
              height: 34.r,
              decoration: BoxDecoration(
                color: palette.background,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppIcons.icon(
                  iconPath,
                  size: 16.sp,
                  color: palette.ink,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            AppIcons.icon(
              AppIcons.forward,
              size: 20.sp,
              color: palette.muted,
            ),
          ],
        ),
      ),
    );
  }

  /// Custom Toggle Switch Row matching Figma exactly
  Widget _buildDarkThemeRow({
    required bool isDark,
    required DaymarkPalette palette,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(18.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 34.r,
              height: 34.r,
              decoration: BoxDecoration(
                color: palette.background,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppIcons.icon(
                  AppIcons.darkMode,
                  size: 16.sp,
                  color: palette.ink,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dark theme",
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Use calm dark appearance",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            // Custom Figma Capsule Toggle Switch (40x22, rx 11)
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                width: 40.w,
                height: 22.h,
                padding: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  color: isDark ? palette.accent : palette.line,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 16.r,
                    height: 16.r,
                    decoration: BoxDecoration(
                      color: palette.onAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
