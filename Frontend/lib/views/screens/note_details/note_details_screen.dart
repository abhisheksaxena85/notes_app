import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/utils/services/note_data_transfer_service.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/viewmodel/note_details/note_details_state.dart';
import 'package:notes_app/viewmodel/note_details/note_details_viewmodel.dart';
import 'package:notes_app/views/screens/note_details/widgets/build_note_form_widget.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_details_app_bar.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_details_error_widget.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_details_loading_widget.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/confirm_dialog.dart';
import 'package:notes_app/views/widgets/sheet_scaffold.dart';

class NoteDetailsScreen extends ConsumerStatefulWidget {
  final int? noteId;

  const NoteDetailsScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends ConsumerState<NoteDetailsScreen> {
  /// FIX-01: the shared confirmation, then the delete (which closes the
  /// editor).
  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    NoteDetailsViewmodel notifier,
  ) async {
    final title = notifier.titleController.text;
    if (!await confirmDelete(context, kind: 'note', itemTitle: title)) return;
    if (context.mounted) await notifier.deleteNote(context);
  }

  /// "More" in the top bar: export or delete the note.
  void _showMoreSheet(
    BuildContext context,
    NoteDetailsState noteState,
    NoteDetailsViewmodel notifier,
  ) {
    final palette = context.daymark;
    showDaymarkSheet<void>(
      context,
      builder: (sheetContext) => SheetScaffold(
        title: "Note",
        child: Column(
          children: [
            _sheetRow(
              palette: palette,
              icon: AppIcons.export,
              title: "Export note",
              subtitle: "Copy as CSV, plain text or JSON",
              onTap: () {
                Navigator.pop(sheetContext);
                _showExportNoteModal(context, noteState, notifier);
              },
            ),
            _sheetRow(
              palette: palette,
              icon: AppIcons.delete,
              title: "Delete note",
              danger: true,
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteConfirmationDialog(context, notifier);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportNoteModal(
    BuildContext context,
    NoteDetailsState noteState,
    NoteDetailsViewmodel notifier,
  ) {
    final palette = context.daymark;
    final item = NoteExportItem(
      noteId: noteState.noteId,
      title: notifier.titleController.text.trim().isEmpty
          ? (noteState.noteData?.title ?? 'Untitled')
          : notifier.titleController.text.trim(),
      content: notifier.contentController.text.trim().isEmpty
          ? (noteState.noteData?.content ?? '')
          : notifier.contentController.text.trim(),
      category: noteState.selectedCategory,
      pinned: noteState.isPinned,
      tags: noteState.noteData?.tags,
      createdAt: noteState.createdAt,
      updatedAt: noteState.updatedAt,
    );

    void export(BuildContext modalCtx, NoteExportFormat format, String label) {
      final text = NoteDataTransferService.exportSingleNote(item, format);
      Clipboard.setData(ClipboardData(text: text));
      Navigator.pop(modalCtx);
      ScaffoldMessenger.of(context).showSnackBar(
        successSnackBar("Note copied as $label to clipboard!"),
      );
    }

    showDaymarkSheet<void>(
      context,
      builder: (modalCtx) => SheetScaffold(
        title: "Export note",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Choose a format to copy this note to your clipboard.",
              style: DaymarkText.preview.copyWith(color: palette.muted),
            ),
            const SizedBox(height: 8),
            _sheetRow(
              palette: palette,
              materialIcon: Icons.table_chart_outlined,
              title: "CSV (Spreadsheet)",
              subtitle: "Comma-separated row with title, content, tags",
              onTap: () => export(modalCtx, NoteExportFormat.csv, "CSV"),
            ),
            _sheetRow(
              palette: palette,
              materialIcon: Icons.text_snippet_outlined,
              title: "Plain Text (.txt)",
              subtitle: "Human-readable formatted text document",
              onTap: () => export(modalCtx, NoteExportFormat.txt, "Plain Text"),
            ),
            _sheetRow(
              palette: palette,
              materialIcon: Icons.code_rounded,
              title: "JSON Object",
              subtitle: "Structured JSON payload with all attributes",
              onTap: () => export(modalCtx, NoteExportFormat.json, "JSON"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetRow({
    required DaymarkPalette palette,
    required String title,
    required VoidCallback onTap,
    String? icon,
    IconData? materialIcon,
    String? subtitle,
    bool danger = false,
  }) {
    final color = danger ? palette.danger : palette.inkSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: danger ? palette.dangerSoft : palette.iconTile,
                borderRadius: BorderRadius.circular(10),
              ),
              child: icon != null
                  ? AppIcons.icon(icon, size: 18, color: color)
                  : Icon(materialIcon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DaymarkText.custom(14.5, FontWeight.w500).copyWith(
                      color: danger ? palette.danger : palette.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: DaymarkText.meta.copyWith(color: palette.muted)),
                  ],
                ],
              ),
            ),
            if (!danger) AppIcons.icon(AppIcons.forward, color: palette.muted, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final provider = noteDetailsController(widget.noteId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: state.when(
          data: (noteState) {
            return Column(
              children: [
                noteDetailsAppBar(
                  context: context,
                  isEditMode: noteState.isEditMode,
                  isPinned: noteState.isPinned,
                  onTogglePin: () => notifier.togglePinned(),
                  onMore: noteState.isEditMode
                      ? () => _showMoreSheet(context, noteState, notifier)
                      : null,
                ),
                Expanded(
                  child: buildNoteFormWidget(
                    context: context,
                    state: noteState,
                    notifier: notifier,
                    onDelete: noteState.isEditMode
                        ? () => _showDeleteConfirmationDialog(context, notifier)
                        : null,
                  ),
                ),
              ],
            );
          },
          loading: () => noteDetailsLoadingWidget(isEditMode: widget.noteId != null),
          error: (error, stack) => noteDetailsErrorWidget(
            message: userMessage(error),
            onRetry: notifier.reload,
          ),
        ),
      ),
    );
  }
}
