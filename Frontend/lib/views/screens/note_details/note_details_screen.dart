import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/utils/services/note_data_transfer_service.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/viewmodel/note_details/note_details_state.dart';
import 'package:notes_app/viewmodel/note_details/note_details_viewmodel.dart';
import 'package:notes_app/views/screens/note_details/widgets/build_note_form_widget.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_details_app_bar.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_details_error_widget.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_details_loading_widget.dart';

class NoteDetailsScreen extends ConsumerStatefulWidget {
  final int? noteId;

  const NoteDetailsScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends ConsumerState<NoteDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(noteDetailsController.notifier).loadNote(widget.noteId);
    });
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    NoteDetailsViewmodel notifier,
  ) {
    final palette = context.daymark;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: palette.line),
        ),
        title: Text(
          "Delete note?",
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this note? This action cannot be undone.",
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: palette.muted,
            height: 1.4,
          ),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: palette.muted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              notifier.deleteNote(context);
            },
            child: Text(
              "Delete",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

    showModalBottomSheet(
      context: context,
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (modalCtx) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
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
                "Export Note",
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Choose a format to copy this note to your clipboard.",
                style: GoogleFonts.inter(fontSize: 12.sp, color: palette.muted),
              ),
              SizedBox(height: 16.h),
              _buildExportOptionTile(
                title: "CSV (Spreadsheet)",
                subtitle: "Comma-separated row with title, content, tags",
                icon: Icons.table_chart_outlined,
                palette: palette,
                onTap: () {
                  final csv = NoteDataTransferService.exportSingleNote(
                    item,
                    NoteExportFormat.csv,
                  );
                  Clipboard.setData(ClipboardData(text: csv));
                  Navigator.pop(modalCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    successSnackBar("Note copied as CSV to clipboard!"),
                  );
                },
              ),
              Divider(color: palette.line, height: 16.h),
              _buildExportOptionTile(
                title: "Plain Text (.txt)",
                subtitle: "Human-readable formatted text document",
                icon: Icons.text_snippet_outlined,
                palette: palette,
                onTap: () {
                  final txt = NoteDataTransferService.exportSingleNote(
                    item,
                    NoteExportFormat.txt,
                  );
                  Clipboard.setData(ClipboardData(text: txt));
                  Navigator.pop(modalCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    successSnackBar("Note copied as Plain Text to clipboard!"),
                  );
                },
              ),
              Divider(color: palette.line, height: 16.h),
              _buildExportOptionTile(
                title: "JSON Object",
                subtitle: "Structured JSON payload with all attributes",
                icon: Icons.code_rounded,
                palette: palette,
                onTap: () {
                  final json = NoteDataTransferService.exportSingleNote(
                    item,
                    NoteExportFormat.json,
                  );
                  Clipboard.setData(ClipboardData(text: json));
                  Navigator.pop(modalCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    successSnackBar("Note copied as JSON to clipboard!"),
                  );
                },
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required DaymarkPalette palette,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: palette.accent, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.muted, size: 20.sp),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final state = ref.watch(noteDetailsController);
    final notifier = ref.read(noteDetailsController.notifier);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: state.when(
          data: (noteState) {
            return Column(
              children: [
                noteDetailsAppBar(
                  context: context,
                  isEditMode: noteState.isEditMode,
                  isPinned: noteState.isPinned,
                  onTogglePin: () => notifier.togglePinned(),
                  onDelete: noteState.isEditMode
                      ? () => _showDeleteConfirmationDialog(context, notifier)
                      : null,
                  onExport: noteState.isEditMode
                      ? () => _showExportNoteModal(context, noteState, notifier)
                      : null,
                ),
                Expanded(
                  child: buildNoteFormWidget(
                    context: context,
                    state: noteState,
                    notifier: notifier,
                  ),
                ),
              ],
            );
          },
          loading: () => noteDetailsLoadingWidget(),
          error: (error, stack) => noteDetailsErrorWidget(
            message: error.toString(),
            onRetry: () => notifier.loadNote(widget.noteId),
          ),
        ),
      ),
    );
  }
}
