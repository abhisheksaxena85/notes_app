import 'package:notes_app/data/network/dto/response/note/note_details_response_dto.dart';

class NoteDetailsState {
  final NoteDetailsData? noteData;
  final bool isEditMode;
  final int? noteId;
  final String selectedCategory;
  final bool isPinned;
  final bool isSaving;
  final String? titleErrorMsg;
  final String? contentErrorMsg;
  final String? createdAt;
  final String? updatedAt;

  const NoteDetailsState({
    this.noteData,
    this.isEditMode = false,
    this.noteId,
    this.selectedCategory = "General",
    this.isPinned = false,
    this.isSaving = false,
    this.titleErrorMsg,
    this.contentErrorMsg,
    this.createdAt,
    this.updatedAt,
  });

  NoteDetailsState copyWith({
    NoteDetailsData? noteData,
    bool? isEditMode,
    int? noteId,
    String? selectedCategory,
    bool? isPinned,
    bool? isSaving,
    String? titleErrorMsg,
    String? contentErrorMsg,
    String? createdAt,
    String? updatedAt,
  }) {
    return NoteDetailsState(
      noteData: noteData ?? this.noteData,
      isEditMode: isEditMode ?? this.isEditMode,
      noteId: noteId ?? this.noteId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isPinned: isPinned ?? this.isPinned,
      isSaving: isSaving ?? this.isSaving,
      titleErrorMsg: titleErrorMsg ?? this.titleErrorMsg,
      contentErrorMsg: contentErrorMsg ?? this.contentErrorMsg,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
