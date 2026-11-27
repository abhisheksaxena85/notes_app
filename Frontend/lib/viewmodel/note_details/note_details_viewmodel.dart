import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/note/update_note_request_dto.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/utils/res/api_error.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/viewmodel/note_details/note_details_state.dart';

/// FE-06: one instance per open note (family keyed by [noteId], auto-disposed
/// when the screen closes), so opening note B never shows note A first.
class NoteDetailsViewmodel extends AsyncNotifier<NoteDetailsState> {
  NoteDetailsViewmodel(this.noteId);

  /// The note being edited; null when creating one.
  final int? noteId;

  final NoteRepo _noteRepo = getIt<NoteRepo>();

  /// MARK: Controllers
  /// Created per build and disposed with it (see [build]).
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  Future<NoteDetailsState> build() async {
    // A different user starts from an empty form.
    ref.watch(sessionUserIdProvider);

    final title = TextEditingController();
    final content = TextEditingController();
    titleController = title;
    contentController = content;
    ref.onDispose(() {
      title.dispose();
      content.dispose();
    });

    final id = noteId;
    if (id == null) {
      // Create mode
      return const NoteDetailsState(
        isEditMode: false,
        selectedCategory: "General",
        isPinned: false,
      );
    }

    // Edit mode: fetch note details
    try {
      log("Fetching note details for noteId: $id");
      final response = await _noteRepo.getNoteDetails(getUserId(), id);
      final noteData = response.data;
      title.text = noteData?.title ?? "";
      content.text = noteData?.content ?? "";
      return NoteDetailsState(
        noteData: noteData,
        isEditMode: true,
        noteId: id,
        selectedCategory:
            (noteData?.category != null && noteData!.category!.isNotEmpty)
            ? noteData.category!
            : "General",
        isPinned: noteData?.pinned ?? false,
        createdAt: noteData?.createdAt,
        updatedAt: noteData?.updatedAt,
      );
    } catch (e) {
      log("Error while fetching note details: $e");
      // Shown as-is by the screen: a short message, never the raw exception.
      throw ApiError.from(e);
    }
  }

  int getUserId() {
    return ref.read(sessionUserIdProvider);
  }

  /// Loads the note again (the error screen's Retry).
  void reload() => ref.invalidateSelf();

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
      state = AsyncData(
        current.copyWith(titleErrorMsg: "Title cannot be empty"),
      );
    } else {
      state = AsyncData(current.copyWith(titleErrorMsg: ""));
    }
  }

  void validateContent(String value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(contentErrorMsg: ""));
  }

  Future<void> saveOrUpdateNote(BuildContext context, {String? tags}) async {
    final current = state.value;
    if (current == null) return;

    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty) {
      state = AsyncData(
        current.copyWith(titleErrorMsg: "Title cannot be empty"),
      );
      return;
    }

    state = AsyncData(current.copyWith(isSaving: true, titleErrorMsg: ""));

    try {
      if (current.isEditMode && current.noteId != null) {
        // Update Note Flow
        // Saved locally first (also for notes that were never uploaded, and
        // offline); the sync service sends it to the server.
        log("Updating note ${current.noteId}...");
        await _noteRepo.updateNote(
          getUserId(),
          UpdateNoteRequestDto(
            noteId: current.noteId,
            title: title,
            content: content,
            category: current.selectedCategory,
            pinned: current.isPinned,
            tags: tags,
          ),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            successSnackBar("Note updated. Syncing in the background."),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Create Note Flow
        final userId = getUserId();
        log("Creating note for userId: $userId...");
        await _noteRepo.enqueueNote(
          CreateNoteRequestDto(
            userId: userId,
            title: title,
            content: content,
            category: current.selectedCategory,
            pinned: current.isPinned,
            tags: tags,
          ),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            successSnackBar("Note saved. Syncing in the background."),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      log("Error while saving note: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(failedSnackBar(userMessage(e)));
      }
    } finally {
      // The screen may have closed (auto-dispose) while saving.
      if (ref.mounted && state.value != null) {
        state = AsyncData(state.value!.copyWith(isSaving: false));
      }
    }
  }

  Future<void> deleteNote(BuildContext context) async {
    final current = state.value;
    final noteId = current?.noteId;
    if (noteId == null) return;

    state = AsyncData(current!.copyWith(isSaving: true));
    try {
      log("Deleting note $noteId...");
      await _noteRepo.deleteNote(getUserId(), noteId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          successSnackBar("Note deleted."),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      log("Error while deleting note: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(failedSnackBar(userMessage(e)));
      }
    } finally {
      // The screen may have closed (auto-dispose) while saving.
      if (ref.mounted && state.value != null) {
        state = AsyncData(state.value!.copyWith(isSaving: false));
      }
    }
  }
}
