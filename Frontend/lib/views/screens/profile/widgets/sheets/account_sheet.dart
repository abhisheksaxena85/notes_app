import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/response/profile/profile_response_dto.dart';
import 'package:notes_app/data/repository/profile/profile_repo.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/logout_sheet.dart';

/// Profile → Account: details, edit profile and delete account.
void showAccountDetailsSheet(
  BuildContext context,
  WidgetRef ref,
  ProfileData profileData,
) {
  final palette = context.daymark;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h)
            .copyWith(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Account Details",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showEditProfileSheet(context, ref, profileData);
                  },
                  icon: AppIcons.icon(AppIcons.edit, size: 16.sp, color: palette.accent),
                  label: Text(
                    "Edit",
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: palette.accent,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildDetailRow("Name", profileData.name ?? "Daymark User", palette),
            Divider(color: palette.line, height: 24.h),
            _buildDetailRow("Email", profileData.email ?? "Not available", palette),
            Divider(color: palette.line, height: 24.h),
            _buildDetailRow("Mobile", profileData.mobile?.isNotEmpty == true ? profileData.mobile! : "Not set", palette),
            Divider(color: palette.line, height: 24.h),
            _buildDetailRow("Gender", profileData.gender?.isNotEmpty == true ? profileData.gender! : "Not set", palette),
            Divider(color: palette.line, height: 24.h),
            _buildDetailRow("User ID", "${profileData.id ?? ref.read(sessionUserIdProvider)}", palette),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmDeleteAccount(context, ref);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: palette.danger.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
                child: Text(
                  "Delete Account",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.danger,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showEditProfileSheet(
  BuildContext context,
  WidgetRef ref,
  ProfileData profileData,
) {
  final palette = context.daymark;
  final nameController = TextEditingController(text: profileData.name ?? "");
  final mobileController = TextEditingController(text: profileData.mobile ?? "");
  String selectedGender = profileData.gender ?? "Male";
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h)
                .copyWith(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h),
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
                  "Edit Profile",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    labelStyle: GoogleFonts.inter(color: palette.muted, fontSize: 13.sp),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: palette.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: palette.accent, width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Mobile Number",
                    labelStyle: GoogleFonts.inter(color: palette.muted, fontSize: 13.sp),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: palette.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: palette.accent, width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  "Gender",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: ["Male", "Female", "Other"].map((g) {
                    final isSelected = selectedGender.toLowerCase() == g.toLowerCase();
                    return Padding(
                      padding: EdgeInsets.only(right: 10.w),
                      child: ChoiceChip(
                        label: Text(
                          g,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? palette.onAccent : palette.ink,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: palette.accent,
                        backgroundColor: palette.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => selectedGender = g);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final mobile = mobileController.text.trim();
                            if (name.isEmpty) return;

                            setModalState(() => isSaving = true);
                            try {
                              final userId = ref.read(sessionUserIdProvider);
                              await getIt<ProfileRepo>().updateProfile(
                                userId: userId,
                                name: name,
                                mobile: mobile,
                                gender: selectedGender,
                              );
                              await ref.read(profileController.notifier).getUserDetails();
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  successSnackBar("Profile updated successfully!"),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  failedSnackBar(userMessage(e)),
                                );
                              }
                            } finally {
                              setModalState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                    child: isSaving
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(color: palette.onAccent, strokeWidth: 2),
                          )
                        : Text(
                            "Save Changes",
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: palette.onAccent,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
  final palette = context.daymark;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        "Delete Account",
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: palette.danger),
      ),
      content: Text(
        "Are you sure you want to permanently delete your account and all associated notes? This action cannot be undone.",
        style: GoogleFonts.inter(fontSize: 13.sp, color: palette.muted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text("Cancel", style: GoogleFonts.inter(color: palette.muted)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final userId = ref.read(sessionUserIdProvider);
            try {
              await getIt<ProfileRepo>().deleteUser(userId);
              // The account is gone, so its unsynced changes can't be
              // kept: sign out and wipe without asking.
              if (context.mounted) {
                await logOutAndShowLogin(context);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  failedSnackBar(userMessage(e)),
                );
              }
            }
          },
          child: Text("Delete Permanently", style: GoogleFonts.inter(color: palette.danger, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value, DaymarkPalette palette) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          color: palette.muted,
        ),
      ),
      Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: palette.ink,
        ),
      ),
    ],
  );
}
