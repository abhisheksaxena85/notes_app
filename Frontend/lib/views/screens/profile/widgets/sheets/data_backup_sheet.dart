import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/utils/services/note_data_transfer_service.dart';
import 'package:notes_app/utils/services/note_export_file.dart';
import 'package:notes_app/viewmodel/controllers.dart';

/// Profile → Data & backup: export (file or clipboard) and import notes.
void showDataBackupSheet(BuildContext context, WidgetRef ref) {
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
                    // FE-06: a file through the share sheet (save or send);
                    // large exports don't fit the Android clipboard.
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: Builder(
                        builder: (buttonContext) => ElevatedButton.icon(
                          onPressed: () async {
                            final box = buttonContext.findRenderObject() as RenderBox?;
                            final origin = box == null
                                ? null
                                : box.localToGlobal(Offset.zero) & box.size;
                            try {
                              await NoteExportFile.share(
                                previewString,
                                exportFormat,
                                origin: origin,
                              );
                            } catch (e) {
                              debugPrint('Export share failed: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  failedSnackBar(
                                    "Couldn't create the export file. Try copying it instead.",
                                  ),
                                );
                              }
                            }
                          },
                          icon: AppIcons.icon(
                            AppIcons.export,
                            color: palette.onAccent,
                            size: 18,
                          ),
                          label: Text(
                            "Save / Share .${NoteExportFile.extension(exportFormat)} file",
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: palette.onAccent,
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
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: double.infinity,
                      height: 44.h,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: previewString));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            successSnackBar(
                              "${exportFormat.name.toUpperCase()} export copied to clipboard (${exportItems.length} notes)!",
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.copy_rounded,
                          color: palette.ink,
                          size: 18,
                        ),
                        label: Text(
                          "Copy ${exportFormat.name.toUpperCase()} to Clipboard",
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: palette.line),
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
                          icon: AppIcons.icon(
                            AppIcons.import,
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
                          AppIcons.icon(
                            AppIcons.info,
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
                                      failedSnackBar("Import failed. ${userMessage(e)}"),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: palette.onAccent,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppIcons.icon(
                                    AppIcons.import,
                                    color: palette.onAccent,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "Import & Sync Notes",
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: palette.onAccent,
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
