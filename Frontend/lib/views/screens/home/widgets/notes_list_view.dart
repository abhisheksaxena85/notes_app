import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/views/screens/home/widgets/note_item_card.dart';

Widget notesListView({
  required List<NoteItem> notes,
  required Future<void> Function() onRefresh,
  void Function(NoteItem)? onNoteTap,
  void Function(NoteItem)? onNoteMoreTap,
}) {
  return RefreshIndicator(
    onRefresh: onRefresh,
    color: AppColors.accentLight,
    child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h).copyWith(
        bottom: 90.h,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return noteItemCard(
          context: context,
          note: note,
          onTap: () {
            if (onNoteTap != null) {
              onNoteTap(note);
            }
          },
          onMoreTap: () {
            if (onNoteMoreTap != null) {
              onNoteMoreTap(note);
            } else if (onNoteTap != null) {
              onNoteTap(note);
            }
          },
        );
      },
    ),
  );
}
