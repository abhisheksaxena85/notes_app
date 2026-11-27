import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/response/profile/profile_response_dto.dart';
import 'package:notes_app/data/repository/profile/profile_repo.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/screens/profile/widgets/sheets/logout_sheet.dart';
import 'package:notes_app/views/widgets/daymark_chip.dart';
import 'package:notes_app/views/widgets/labeled_field.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/sheet_scaffold.dart';

/// Profile → Account: details, edit profile and delete account.
void showAccountDetailsSheet(
  BuildContext context,
  WidgetRef ref,
  ProfileData profileData,
) {
  final palette = context.daymark;
  showDaymarkSheet<void>(
    context,
    builder: (ctx) {
      final rows = [
        ("Name", profileData.name ?? "Daymark User"),
        ("Email", profileData.email ?? "Not available"),
        ("Mobile", profileData.mobile?.isNotEmpty == true ? profileData.mobile! : "Not set"),
        ("Gender", profileData.gender?.isNotEmpty == true ? profileData.gender! : "Not set"),
        ("User ID", "${profileData.id ?? ref.read(sessionUserIdProvider)}"),
      ];
      return SheetScaffold(
        title: "Account details",
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () {
              Navigator.pop(ctx);
              _showEditProfileSheet(context, ref, profileData);
            },
            icon: AppIcons.icon(AppIcons.edit, size: 20, color: palette.accent),
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: palette.divider),
              _buildDetailRow(rows[i].$1, rows[i].$2, palette),
            ],
            const SizedBox(height: 20),
            OutlineButton(
              label: "Delete account",
              icon: AppIcons.delete,
              color: palette.danger,
              borderColor: palette.dangerBorder,
              onPressed: () {
                Navigator.pop(ctx);
                _confirmDeleteAccount(context, ref);
              },
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
  final nameController = TextEditingController(text: profileData.name ?? "");
  final mobileController = TextEditingController(text: profileData.mobile ?? "");
  String selectedGender = profileData.gender ?? "Male";
  bool isSaving = false;

  showDaymarkSheet<void>(
    context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final palette = context.daymark;
          final fieldStyle = DaymarkText.custom(15, FontWeight.w400).copyWith(color: palette.ink);
          return SheetScaffold(
            title: "Edit profile",
            footer: PrimaryButton(
              label: "Save changes",
              loading: isSaving,
              onPressed: () async {
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: "Full name",
                  child: TextField(
                    controller: nameController,
                    style: fieldStyle,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: "Mobile number",
                  child: TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    style: fieldStyle,
                  ),
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: "Gender",
                  child: Row(
                    children: [
                      for (final g in const ["Male", "Female", "Other"]) ...[
                        DaymarkChip(
                          label: g,
                          style: DaymarkChipStyle.category,
                          selected: selectedGender.toLowerCase() == g.toLowerCase(),
                          onTap: () => setModalState(() => selectedGender = g),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
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
      title: const Text("Delete account?"),
      content: Text(
        "Are you sure you want to permanently delete your account and all associated notes? This action cannot be undone.",
        style: DaymarkText.preview.copyWith(color: palette.inkSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            "Cancel",
            style: DaymarkText.custom(14, FontWeight.w600).copyWith(color: palette.muted),
          ),
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
          child: Text(
            "Delete permanently",
            style: DaymarkText.custom(14, FontWeight.w600).copyWith(color: palette.danger),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value, DaymarkPalette palette) {
  return SizedBox(
    height: 48,
    child: Row(
      children: [
        Text(label, style: DaymarkText.custom(14, FontWeight.w400).copyWith(color: palette.muted)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DaymarkText.custom(14.5, FontWeight.w500).copyWith(color: palette.ink),
          ),
        ),
      ],
    ),
  );
}
