import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/response/profile/profile_response_dto.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/repository/profile/profile_repo.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/utils/services/local_reminder_service.dart';
import 'package:notes_app/utils/services/note_data_transfer_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/auth/login/login_screen.dart';

class BuildProfileWidget extends ConsumerWidget {
  final ProfileData profileData;

  const BuildProfileWidget({super.key, required this.profileData});

  void _showAccountDetailsModal(BuildContext context, WidgetRef ref) {
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
                      _showEditProfileModal(context, ref);
                    },
                    icon: Icon(Icons.edit_rounded, size: 16.sp, color: palette.accent),
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

  void _showEditProfileModal(BuildContext context, WidgetRef ref) {
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
                              color: isSelected ? Colors.white : palette.ink,
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
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              "Save Changes",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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

  void _showNotificationsModal(BuildContext context) {
    final palette = context.daymark;
    bool isDaily = LocalReminderService.isDailyReminderEnabled();
    TimeOfDay reminderTime = LocalReminderService.getDailyReminderTime();
    bool isWeekly = LocalReminderService.isWeeklySummaryEnabled();

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
                  SizedBox(height: 20.h),
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
                          setModalState(() => isDaily = val);
                          await LocalReminderService.setDailyReminder(val, time: reminderTime);
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
                          await LocalReminderService.setDailyReminder(true, time: picked);
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
                          setModalState(() => isWeekly = val);
                          await LocalReminderService.setWeeklySummary(val);
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

  void _showDataBackupModal(BuildContext context, WidgetRef ref) {
    final palette = context.daymark;
    final homeState = ref.read(homeController);
    final notes = homeState.value?.notesData?.data ?? [];
    final userId = ref.read(sessionUserIdProvider);
    final exportItems = notes.map(NoteExportItem.fromNoteItem).toList();

    int activeTab = 0; // 0: Export, 1: Import
    NoteExportFormat exportFormat = NoteExportFormat.csv;
    NoteExportFormat? importFormat; // null = Auto-detect
    final importTextController = TextEditingController();
    bool isImporting = false;
    String? validationInfo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final previewString = NoteDataTransferService.exportNotes(
              exportItems,
              exportFormat,
              userId: userId,
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 16.h,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38.w,
                        height: 4.h,
                        margin: EdgeInsets.only(bottom: 14.h),
                        decoration: BoxDecoration(
                          color: palette.line,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    Text(
                      "Data Backup & Sync",
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Export or import notes as CSV, TXT, or JSON. Imported notes sync with your server database.",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: palette.muted,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Tab selector (Export / Import)
                    Container(
                      height: 38.h,
                      padding: EdgeInsets.all(3.r),
                      decoration: BoxDecoration(
                        color: palette.background,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: palette.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: activeTab == 0
                                      ? palette.surface
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9.r),
                                  boxShadow: activeTab == 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.04,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "Export Notes",
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: activeTab == 0
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: activeTab == 0
                                        ? palette.ink
                                        : palette.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 1),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: activeTab == 1
                                      ? palette.surface
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9.r),
                                  boxShadow: activeTab == 1
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.04,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "Import Notes",
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: activeTab == 1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: activeTab == 1
                                        ? palette.ink
                                        : palette.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    if (activeTab == 0) ...[
                      // Export Format selector chips
                      Row(
                        children: [
                          Text(
                            "Format:",
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _buildFormatChip(
                            label: "CSV",
                            isSelected: exportFormat == NoteExportFormat.csv,
                            palette: palette,
                            onTap: () => setModalState(
                              () => exportFormat = NoteExportFormat.csv,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          _buildFormatChip(
                            label: "Plain Text (.txt)",
                            isSelected: exportFormat == NoteExportFormat.txt,
                            palette: palette,
                            onTap: () => setModalState(
                              () => exportFormat = NoteExportFormat.txt,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          _buildFormatChip(
                            label: "JSON",
                            isSelected: exportFormat == NoteExportFormat.json,
                            palette: palette,
                            onTap: () => setModalState(
                              () => exportFormat = NoteExportFormat.json,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        "${exportItems.length} notes ready for export.",
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: palette.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        height: 140.h,
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: palette.line),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            previewString,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.sp,
                              color: palette.ink,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: previewString));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              successSnackBar(
                                "${exportFormat.name.toUpperCase()} export copied to clipboard (${exportItems.length} notes)!",
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            "Copy ${exportFormat.name.toUpperCase()} to Clipboard",
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.accent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Import Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Import Format:",
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () async {
                              final data =
                                  await Clipboard.getData(Clipboard.kTextPlain);
                              if (data?.text != null &&
                                  data!.text!.isNotEmpty) {
                                importTextController.text = data.text!;
                                final parsed =
                                    NoteDataTransferService.parseNotes(
                                  data.text!,
                                  importFormat,
                                );
                                setModalState(() {
                                  validationInfo =
                                      "Format: ${(importFormat?.name ?? NoteDataTransferService.detectFormat(data.text!).name).toUpperCase()} • ${parsed.length} note(s) detected";
                                });
                              }
                            },
                            icon: Icon(
                              Icons.paste_rounded,
                              size: 14.sp,
                              color: palette.accent,
                            ),
                            label: Text(
                              "Paste from clipboard",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: palette.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 6.w,
                        children: [
                          _buildFormatChip(
                            label: "Auto-detect",
                            isSelected: importFormat == null,
                            palette: palette,
                            onTap: () {
                              setModalState(() {
                                importFormat = null;
                                if (importTextController.text.trim().isNotEmpty) {
                                  final parsed =
                                      NoteDataTransferService.parseNotes(
                                    importTextController.text,
                                  );
                                  validationInfo =
                                      "Detected: ${NoteDataTransferService.detectFormat(importTextController.text).name.toUpperCase()} • ${parsed.length} note(s)";
                                }
                              });
                            },
                          ),
                          _buildFormatChip(
                            label: "CSV",
                            isSelected: importFormat == NoteExportFormat.csv,
                            palette: palette,
                            onTap: () {
                              setModalState(() {
                                importFormat = NoteExportFormat.csv;
                                if (importTextController.text.trim().isNotEmpty) {
                                  final parsed =
                                      NoteDataTransferService.parseNotes(
                                    importTextController.text,
                                    NoteExportFormat.csv,
                                  );
                                  validationInfo =
                                      "${parsed.length} CSV note(s) parsed";
                                }
                              });
                            },
                          ),
                          _buildFormatChip(
                            label: "TXT",
                            isSelected: importFormat == NoteExportFormat.txt,
                            palette: palette,
                            onTap: () {
                              setModalState(() {
                                importFormat = NoteExportFormat.txt;
                                if (importTextController.text.trim().isNotEmpty) {
                                  final parsed =
                                      NoteDataTransferService.parseNotes(
                                    importTextController.text,
                                    NoteExportFormat.txt,
                                  );
                                  validationInfo =
                                      "${parsed.length} TXT note(s) parsed";
                                }
                              });
                            },
                          ),
                          _buildFormatChip(
                            label: "JSON",
                            isSelected: importFormat == NoteExportFormat.json,
                            palette: palette,
                            onTap: () {
                              setModalState(() {
                                importFormat = NoteExportFormat.json;
                                if (importTextController.text.trim().isNotEmpty) {
                                  final parsed =
                                      NoteDataTransferService.parseNotes(
                                    importTextController.text,
                                    NoteExportFormat.json,
                                  );
                                  validationInfo =
                                      "${parsed.length} JSON note(s) parsed";
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: palette.line),
                        ),
                        child: TextField(
                          controller: importTextController,
                          maxLines: 5,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11.sp,
                            color: palette.ink,
                          ),
                          onChanged: (val) {
                            if (val.trim().isEmpty) {
                              setModalState(() => validationInfo = null);
                            } else {
                              final parsed = NoteDataTransferService.parseNotes(
                                val,
                                importFormat,
                              );
                              final detected = importFormat?.name ??
                                  NoteDataTransferService.detectFormat(val)
                                      .name;
                              setModalState(() {
                                validationInfo =
                                    "Format: ${detected.toUpperCase()} • ${parsed.length} note(s) detected";
                              });
                            }
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(12.r),
                            border: InputBorder.none,
                            hintText:
                                "Paste notes data in CSV, TXT, or JSON format...",
                            hintStyle: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: palette.muted,
                            ),
                          ),
                        ),
                      ),
                      if (validationInfo != null) ...[
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 13.sp,
                              color: palette.accent,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              validationInfo!,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: palette.accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: isImporting
                              ? null
                              : () async {
                                  final text =
                                      importTextController.text.trim();
                                  if (text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      failedSnackBar(
                                        "Please paste or enter data to import.",
                                      ),
                                    );
                                    return;
                                  }

                                  final parsed =
                                      NoteDataTransferService.parseNotes(
                                    text,
                                    importFormat,
                                  );

                                  if (parsed.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      failedSnackBar(
                                        "No valid notes detected in the input data.",
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => isImporting = true);

                                  try {
                                    final noteRepo = getIt<NoteRepo>();
                                    final result = await noteRepo.importNotes(
                                      userId: userId,
                                      notes: parsed,
                                    );

                                    // Refresh notes list in UI
                                    await ref
                                        .read(homeController.notifier)
                                        .getAllNotes(id: userId);

                                    if (modalContext.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        successSnackBar(result.summary),
                                      );
                                    }
                                  } catch (e) {
                                    setModalState(() => isImporting = false);
                                    if (modalContext.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        failedSnackBar("Import failed: $e"),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.accent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: isImporting
                              ? SizedBox(
                                  width: 20.r,
                                  height: 20.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.file_upload_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      "Import & Sync Notes",
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormatChip({
    required String label,
    required bool isSelected,
    required DaymarkPalette palette,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected ? palette.accentSoft : palette.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? palette.accent : palette.line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? palette.accent : palette.muted,
          ),
        ),
      ),
    );
  }

  void _showHelpModal(BuildContext context) {
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
                "Help & FAQ",
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              SizedBox(height: 16.h),
              _buildFaqItem("How does the Calendar count notes?", "Notes are counted strictly by their original creation date (createdAt). Editing a note never shifts its calendar timestamp.", palette),
              Divider(color: palette.line, height: 20.h),
              _buildFaqItem("How do offline notes work?", "When you are offline, new notes are stored locally in an encrypted Drift SQLite queue. When network connectivity resumes, the background sync service pushes them to the server.", palette),
              Divider(color: palette.line, height: 20.h),
              _buildFaqItem("Can I organize notes with tags?", "Yes! You can assign categories and custom tags to any note. Search searches across titles, content, categories, and tags.", palette),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer, DaymarkPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          answer,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: palette.muted,
            height: 1.4,
          ),
        ),
      ],
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
                  await _logout(context);
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

  void _showInfoDialog(BuildContext context, String title, String message) {
    final palette = context.daymark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: palette.line),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: palette.muted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "OK",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: palette.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final palette = context.daymark;
    // Signing out wipes this user's data from the device, including changes
    // that haven't reached the server yet: say so before they are lost.
    final unsynced = await getIt<SessionService>().unsyncedChangeCount();
    if (!context.mounted) return;
    final String message;
    if (unsynced == 0) {
      message = "Are you sure you want to sign out of Daymark on this device?";
    } else {
      final changes = unsynced == 1 ? "1 change" : "$unsynced changes";
      message =
          "$changes on this device ${unsynced == 1 ? "hasn't" : "haven't"} been synced yet. "
          "Signing out deletes ${unsynced == 1 ? "it" : "them"} for good.\n\n"
          "To keep ${unsynced == 1 ? "it" : "them"}, cancel, go online and wait for the sync to finish.";
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          unsynced == 0 ? "Sign Out" : "Unsynced changes",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: palette.ink),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13.sp, color: palette.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: palette.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout(context);
            },
            child: Text(
              unsynced == 0 ? "Sign Out" : "Sign Out Anyway",
              style: GoogleFonts.inter(color: palette.danger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Ends the session, wipes the user's local data and resets every
  /// controller, so the next user starts clean.
  Future<void> _logout(BuildContext context) async {
    // Taken before the await: this widget may be gone by the time it returns.
    final container = ProviderScope.containerOf(context, listen: false);
    await getIt<SessionService>().logout();
    for (final controller in sessionScopedControllers) {
      container.invalidate(controller);
    }
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

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
                        child: Icon(
                          Icons.check_rounded,
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
                          AppIcons.navNotes,
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
                  iconPath: AppIcons.navProfile,
                  title: "Account details",
                  subtitle: "Your profile information & settings",
                  palette: palette,
                  onTap: () => _showAccountDetailsModal(context, ref),
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
                  iconPath: AppIcons.sliders,
                  title: "App preferences",
                  subtitle: "Appearance, theme, and reading options",
                  palette: palette,
                  onTap: () => _showInfoDialog(
                    context,
                    "App Preferences",
                    "Dual light/dark themes are rendered dynamically from the Figma design tokens.\nTypography uses Google Fonts Inter.",
                  ),
                ),
                _buildDivider(palette),

                // Item 4: Notifications
                _buildSettingsRow(
                  iconPath: AppIcons.bell,
                  title: "Notifications",
                  subtitle: "Manage daily reminders and summaries",
                  palette: palette,
                  onTap: () => _showNotificationsModal(context),
                ),
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
                  iconPath: AppIcons.shield,
                  title: "Privacy & security",
                  subtitle: "Understand how notes are stored",
                  palette: palette,
                  onTap: () => _showInfoDialog(
                    context,
                    "Privacy & Security",
                    "Your notes are synchronized with your personal MySQL account over HTTPS and cached locally in an encrypted Drift SQLite database.\n\nLogging out clears all user-scoped data from memory.",
                  ),
                ),
                _buildDivider(palette),
                _buildSettingsRow(
                  iconPath: AppIcons.cloud,
                  title: "Data & backup",
                  subtitle: "Export or import notes as CSV, TXT, or JSON",
                  palette: palette,
                  onTap: () => _showDataBackupModal(context, ref),
                ),
                _buildDivider(palette),
                _buildSettingsRow(
                  iconPath: AppIcons.help,
                  title: "Help & support",
                  subtitle: "FAQs and app documentation",
                  palette: palette,
                  onTap: () => _showHelpModal(context),
                ),
                _buildDivider(palette),
                _buildSettingsRow(
                  iconPath: AppIcons.info,
                  title: "About Daymark",
                  subtitle: "Version and design system",
                  palette: palette,
                  onTap: () => _showInfoDialog(
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
              onPressed: () => _confirmLogout(context),
              icon: Icon(Icons.logout_rounded, color: palette.danger, size: 18.sp),
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
            Icon(
              Icons.chevron_right_rounded,
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
                  AppIcons.moon,
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
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
