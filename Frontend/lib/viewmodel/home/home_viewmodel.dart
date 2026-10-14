import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/local/shared_preference/preference_keys.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/data/repository/home/home_repo.dart';
import 'package:notes_app/viewmodel/home/home_state.dart';

class HomeViewmodel extends AsyncNotifier<HomeState> {
  /// MARK: Variables
  final HomeRepo _homeRepo = HomeRepo();

  /// MARK: DATA
  var notesData = GetAllNotesResponseDto();

  @override
  Future<HomeState> build() async {
    return fetchNotes();
  }

  int getUserId() {
    return getIt<Preference>().getInt(PreferenceKeys.USER_ID) ?? 0;
  }

  Future<HomeState> fetchNotes({int? id}) async {
    final int userId = id ?? getUserId();
    log("Fetching all notes for userId: $userId");
    try {
      final response = await _homeRepo.getAllNotes(userId);
      notesData = response;
      return HomeState(notesData: notesData);
    } catch (e) {
      log("Error while fetching notes! $e");
      rethrow;
    }
  }

  Future<void> getAllNotes({int? id}) async {
    state = const AsyncLoading();
    try {
      final int userId = id ?? getUserId();
      log("Refetching notes for userId: $userId");
      final response = await _homeRepo.getAllNotes(userId);
      notesData = response;
      state = AsyncData(HomeState(notesData: notesData));
    } catch (e, st) {
      log("Error while refetching notes! $e");
      state = AsyncError(e.toString(), st);
    }
  }
}
