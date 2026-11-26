import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/response/profile/profile_response_dto.dart';
import 'package:notes_app/data/repository/profile/profile_repo.dart';
import 'package:notes_app/viewmodel/profile/profile_state.dart';
import 'package:notes_app/viewmodel/controllers.dart';

class ProfileViewmodel extends AsyncNotifier<ProfileState> {
  final ProfileRepo _profileRepo = getIt<ProfileRepo>();

  var profileData = ProfileResponseDto();

  @override
  Future<ProfileState> build() async {
    final userId = ref.watch(sessionUserIdProvider);
    profileData =
        await _profileRepo.getCachedProfile(userId) ?? ProfileResponseDto();

    final subscription = _profileRepo
        .watchProfile(userId)
        .listen(
          (profile) {
            if (profile == null) return;
            profileData = ProfileResponseDto(success: true, data: profile);
            if (state.hasValue) {
              state = AsyncData(ProfileState(profileData: profileData));
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            log(
              'Failed to observe local profile: $error',
              stackTrace: stackTrace,
            );
          },
        );
    ref.onDispose(() {
      subscription.cancel();
    });
    return ProfileState(profileData: profileData);
  }

  int getUserId() {
    return ref.read(sessionUserIdProvider);
  }

  Future<void> getUserDetails({int? id}) async {
    final userId = id ?? getUserId();
    try {
      await _profileRepo.refreshProfile(userId);
    } catch (e, st) {
      log('Failed to refresh profile for user $userId: $e', stackTrace: st);
      if (profileData.data == null) {
        state = AsyncError(e, st);
      }
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String name,
    required String mobile,
    required String gender,
  }) async {
    final userId = getUserId();
    await _profileRepo.updateProfile(
      userId: userId,
      name: name,
      mobile: mobile,
      gender: gender,
    );
    await getUserDetails(id: userId);
  }
}
