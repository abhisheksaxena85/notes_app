import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/controllers.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noteDetailsController);
    final notifier = ref.read(noteDetailsController.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withAlpha(25),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Column(
              children: [
                noteDetailsAppBar(
                  context: context,
                  isEditMode: state.value?.isEditMode ?? (widget.noteId != null),
                  isPinned: state.value?.isPinned ?? false,
                  onTogglePin: () => notifier.togglePinned(),
                ),
                Expanded(
                  child: state.when(
                    data: (noteState) {
                      return buildNoteFormWidget(
                        context: context,
                        state: noteState,
                        notifier: notifier,
                      );
                    },
                    loading: () => noteDetailsLoadingWidget(),
                    error: (error, stack) => noteDetailsErrorWidget(
                      message: error.toString(),
                      onRetry: () => notifier.loadNote(widget.noteId),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
