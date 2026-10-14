import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/viewmodel/note_details/note_details_state.dart';
import 'package:notes_app/viewmodel/note_details/note_details_viewmodel.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_action_button.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_category_selector.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_content_field.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_meta_info_widget.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_title_field.dart';

Widget buildNoteFormWidget({
  required BuildContext context,
  required NoteDetailsState state,
  required NoteDetailsViewmodel notifier,
}) {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        noteCategorySelector(
          selectedCategory: state.selectedCategory,
          onCategorySelected: (cat) => notifier.setCategory(cat),
        ),
        SizedBox(height: 16.h),
        noteTitleField(
          controller: notifier.titleController,
          onChanged: (val) => notifier.validateTitle(val),
          errorText: state.titleErrorMsg,
        ),
        SizedBox(height: 16.h),
        noteContentField(
          controller: notifier.contentController,
          onChanged: (val) => notifier.validateContent(val),
          errorText: state.contentErrorMsg,
        ),
        if (state.isEditMode) ...[
          SizedBox(height: 16.h),
          noteMetaInfoWidget(
            createdAt: state.createdAt,
            updatedAt: state.updatedAt,
          ),
        ],
        SizedBox(height: 24.h),
        noteActionButton(
          isEditMode: state.isEditMode,
          isSaving: state.isSaving,
          onPressed: () => notifier.saveOrUpdateNote(context),
        ),
        SizedBox(height: 16.h),
      ],
    ),
  );
}
