import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/views/screens/home/widgets/note_item_card.dart';

Widget notesListView({
  required List<NoteItem> notes,
  required Future<void> Function() onRefresh,
  void Function(NoteItem)? onNoteTap,
}) {
  // Sort with pinned notes first, then by date/id
  final sortedNotes = List<NoteItem>.from(notes)
    ..sort((a, b) {
      if ((a.pinned ?? false) && !(b.pinned ?? false)) return -1;
      if (!(a.pinned ?? false) && (b.pinned ?? false)) return 1;
      return (b.noteId ?? 0).compareTo(a.noteId ?? 0);
    });

  return RefreshIndicator(
    onRefresh: onRefresh,
    color: AppColors.brandColor,
    child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      itemCount: sortedNotes.length,
      itemBuilder: (context, index) {
        final note = sortedNotes[index];
        return noteItemCard(
          note: note,
          onTap: () {
            if (onNoteTap != null) {
              onNoteTap(note);
            }
          },
        );
      },
    ),
  );
}
