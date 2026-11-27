import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/utils/services/note_data_transfer_service.dart';
import 'package:notes_app/utils/services/note_export_file.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/widgets/daymark_chip.dart';
import 'package:notes_app/views/widgets/labeled_field.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/segmented_control.dart';
import 'package:notes_app/views/widgets/sheet_scaffold.dart';

/// Monospace text for export previews and pasted import data.
TextStyle _codeStyle(Color color) => TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Courier New', 'Courier'],
      fontSize: 11.5,
      height: 1.4,
      color: color,
    );

/// Profile → Data & backup: export (file or clipboard) and import notes.
void showDataBackupSheet(BuildContext context, WidgetRef ref) {
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

  showDaymarkSheet<void>(
    context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (modalContext, setModalState) {
          final palette = modalContext.daymark;
          final previewString = NoteDataTransferService.exportNotes(
            exportItems,
            exportFormat,
            userId: userId,
          );

          /// Picks the import format and re-validates the pasted text.
          void selectImportFormat(NoteExportFormat? format) {
            setModalState(() {
              importFormat = format;
              final text = importTextController.text;
              if (text.trim().isEmpty) return;
              final parsed = format == null
                  ? NoteDataTransferService.parseNotes(text)
                  : NoteDataTransferService.parseNotes(text, format);
              validationInfo = format == null
                  ? "Detected: ${NoteDataTransferService.detectFormat(text).name.toUpperCase()} • ${parsed.length} note(s)"
                  : "${parsed.length} ${format.name.toUpperCase()} note(s) parsed";
            });
          }

          Future<void> runImport() async {
            final text = importTextController.text.trim();
            if (text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                failedSnackBar("Please paste or enter data to import."),
              );
              return;
            }
            final parsed = NoteDataTransferService.parseNotes(text, importFormat);
            if (parsed.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                failedSnackBar("No valid notes detected in the input data."),
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
              await ref.read(homeController.notifier).getAllNotes(id: userId);
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
          }

          final Widget footer = activeTab == 0
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FE-06: a file through the share sheet (save or send);
                    // large exports don't fit the Android clipboard.
                    Builder(
                      builder: (buttonContext) => PrimaryButton(
                        label: "Save / Share .${NoteExportFile.extension(exportFormat)} file",
                        icon: AppIcons.export,
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlineButton(
                      label: "Copy ${exportFormat.name.toUpperCase()} to clipboard",
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: previewString));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          successSnackBar(
                            "${exportFormat.name.toUpperCase()} export copied to clipboard (${exportItems.length} notes)!",
                          ),
                        );
                      },
                    ),
                  ],
                )
              : PrimaryButton(
                  label: "Import & sync notes",
                  icon: AppIcons.import,
                  loading: isImporting,
                  onPressed: runImport,
                );

          return SheetScaffold(
            title: "Data & backup",
            footer: footer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Export or import notes as CSV, TXT, or JSON. Imported notes sync with your server database.",
                  style: DaymarkText.preview.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 14),
                SegmentedControl<int>(
                  segments: const {0: "Export notes", 1: "Import notes"},
                  value: activeTab,
                  onChanged: (tab) => setModalState(() => activeTab = tab),
                ),
                const SizedBox(height: 16),
                if (activeTab == 0) ...[
                  LabeledField(
                    label: "Format",
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (format, label) in const [
                          (NoteExportFormat.csv, "CSV"),
                          (NoteExportFormat.txt, "Plain text (.txt)"),
                          (NoteExportFormat.json, "JSON"),
                        ])
                          DaymarkChip(
                            label: label,
                            style: DaymarkChipStyle.category,
                            selected: exportFormat == format,
                            onTap: () => setModalState(() => exportFormat = format),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${exportItems.length} notes ready for export.",
                    style: DaymarkText.meta.copyWith(color: palette.muted),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.line),
                    ),
                    child: SingleChildScrollView(
                      child: Text(previewString, style: _codeStyle(palette.inkSecondary)),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Import format",
                          style: DaymarkText.label.copyWith(color: palette.inkSecondary),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null && data!.text!.isNotEmpty) {
                            importTextController.text = data.text!;
                            final parsed = NoteDataTransferService.parseNotes(
                              data.text!,
                              importFormat,
                            );
                            setModalState(() {
                              validationInfo =
                                  "Format: ${(importFormat?.name ?? NoteDataTransferService.detectFormat(data.text!).name).toUpperCase()} • ${parsed.length} note(s) detected";
                            });
                          }
                        },
                        icon: AppIcons.icon(AppIcons.import, size: 16, color: palette.accent),
                        label: Text(
                          "Paste from clipboard",
                          style: DaymarkText.custom(13, FontWeight.w500).copyWith(color: palette.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (format, label) in const <(NoteExportFormat?, String)>[
                        (null, "Auto-detect"),
                        (NoteExportFormat.csv, "CSV"),
                        (NoteExportFormat.txt, "TXT"),
                        (NoteExportFormat.json, "JSON"),
                      ])
                        DaymarkChip(
                          label: label,
                          style: DaymarkChipStyle.category,
                          selected: importFormat == format,
                          onTap: () => selectImportFormat(format),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: importTextController,
                    minLines: 5,
                    maxLines: 5,
                    style: _codeStyle(palette.ink),
                    onChanged: (val) {
                      if (val.trim().isEmpty) {
                        setModalState(() => validationInfo = null);
                      } else {
                        final parsed = NoteDataTransferService.parseNotes(
                          val,
                          importFormat,
                        );
                        final detected = importFormat?.name ??
                            NoteDataTransferService.detectFormat(val).name;
                        setModalState(() {
                          validationInfo =
                              "Format: ${detected.toUpperCase()} • ${parsed.length} note(s) detected";
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: "Paste notes data in CSV, TXT, or JSON format...",
                    ),
                  ),
                  if (validationInfo != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppIcons.icon(AppIcons.info, size: 14, color: palette.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            validationInfo!,
                            style: DaymarkText.custom(12.5, FontWeight.w500).copyWith(color: palette.accent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      );
    },
  );
}
