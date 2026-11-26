import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/data/repository/home/home_repo.dart';
import 'package:notes_app/viewmodel/home/home_state.dart';
import 'package:notes_app/viewmodel/controllers.dart';

class HomeViewmodel extends AsyncNotifier<HomeState> {
  final HomeRepo _homeRepo = getIt<HomeRepo>();

  var notesData = GetAllNotesResponseDto();

  @override
  Future<HomeState> build() async {
    final userId = ref.watch(sessionUserIdProvider);
    final cachedNotes = await _homeRepo.getCachedNotes(userId);
    notesData = cachedNotes;

    final subscription = _homeRepo
        .watchNotes(userId)
        .listen(
          (notes) {
            notesData = GetAllNotesResponseDto(success: true, data: notes);
            if (state.hasValue) {
              state = AsyncData(HomeState(notesData: notesData));
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            log(
              'Failed to observe local notes: $error',
              stackTrace: stackTrace,
            );
          },
        );
    ref.onDispose(() {
      subscription.cancel();
    });

    if (userId != 0) {
      unawaited(_refreshNotes(userId));
    }
    return HomeState(notesData: cachedNotes);
  }

  int getUserId() {
    return ref.read(sessionUserIdProvider);
  }

  Future<void> getAllNotes({int? id}) async {
    final userId = id ?? getUserId();
    try {
      await _homeRepo.getAllNotes(userId);
    } catch (error, stackTrace) {
      log(
        'Failed to refresh notes for user $userId: $error',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _refreshNotes(int userId) async {
    try {
      await _homeRepo.getAllNotes(userId);
    } catch (error, stackTrace) {
      log(
        'Failed to refresh notes for user $userId: $error',
        stackTrace: stackTrace,
      );
    }
  }
}
