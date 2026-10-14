import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/local/shared_preference/preference_keys.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/note/update_note_request_dto.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/viewmodel/note_details/note_details_state.dart';

class NoteDetailsViewmodel extends AsyncNotifier<NoteDetailsState> {
  /// MARK: Repository
  final NoteRepo _noteRepo = NoteRepo();

  /// MARK: Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  FutureOr<NoteDetailsState> build() {
    return const NoteDetailsState();
  }

  int getUserId() {
    return getIt<Preference>().getInt(PreferenceKeys.USER_ID) ?? 0;
  }

  Future<void> loadNote(int? noteId) async {
    if (noteId == null) {
      // Create mode
      titleController.clear();
      contentController.clear();
      state = const AsyncData(
        NoteDetailsState(
          isEditMode: false,
          selectedCategory: "General",
          isPinned: false,
        ),
      );
      return;
    }

    // Edit mode: fetch note details
    state = const AsyncLoading();
    try {
      log("Fetching note details for noteId: $noteId");
      final response = await _noteRepo.getNoteDetails(noteId);
      final noteData = response.data;
      titleController.text = noteData?.title ?? "";
      contentController.text = noteData?.content ?? "";
      state = AsyncData(
        NoteDetailsState(
          noteData: noteData,
          isEditMode: true,
          noteId: noteId,
          selectedCategory:
              (noteData?.category != null && noteData!.category!.isNotEmpty)
                  ? noteData.category!
                  : "General",
          isPinned: noteData?.pinned ?? false,
          createdAt: noteData?.createdAt,
          updatedAt: noteData?.updatedAt,
        ),
      );
    } catch (e, st) {
      log("Error while fetching note details: $e");
      state = AsyncError(e.toString(), st);
    }
  }

  void setCategory(String category) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedCategory: category));
  }

  void togglePinned() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isPinned: !current.isPinned));
  }

  void validateTitle(String value) {
    final current = state.value;
    if (current == null) return;
    if (value.trim().isEmpty) {
      state = AsyncData(current.copyWith(titleErrorMsg: "Title cannot be empty"));
    } else {
      state = AsyncData(current.copyWith(titleErrorMsg: ""));
    }
  }

  void validateContent(String value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(contentErrorMsg: ""));
  }

  Future<void> saveOrUpdateNote(BuildContext context) async {
    final current = state.value;
    if (current == null) return;

    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty) {
      state = AsyncData(current.copyWith(titleErrorMsg: "Title cannot be empty"));
      return;
    }

    state = AsyncData(current.copyWith(isSaving: true, titleErrorMsg: ""));

    try {
      if (current.isEditMode && current.noteId != null) {
        // Update Note Flow
        log("Updating note ${current.noteId}...");
        final response = await _noteRepo.updateNote(
          UpdateNoteRequestDto(
            noteId: current.noteId,
            title: title,
            content: content,
            category: current.selectedCategory,
            pinned: current.isPinned,
          ),
        );

        if (response.success == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              successSnackBar(response.message ?? "Note updated successfully!"),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              failedSnackBar(response.message ?? "Failed to update note"),
            );
          }
        }
      } else {
        // Create Note Flow
        final userId = getUserId();
        log("Creating note for userId: $userId...");
        final response = await _noteRepo.createNote(
          CreateNoteRequestDto(
            userId: userId,
            title: title,
            content: content,
            category: current.selectedCategory,
            pinned: current.isPinned,
          ),
        );

        if (response.success == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              successSnackBar(response.message ?? "Note created successfully!"),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              failedSnackBar(response.message ?? "Failed to create note"),
            );
          }
        }
      }
    } catch (e) {
      log("Error while saving note: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          failedSnackBar("An error occurred: $e"),
        );
      }
    } finally {
      if (state.value != null) {
        state = AsyncData(state.value!.copyWith(isSaving: false));
      }
    }
  }
}
