import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/local/shared_preference/preference_keys.dart';
import 'package:notes_app/data/network/dto/request/profile/profile_request_dto.dart';
import 'package:notes_app/data/network/dto/response/profile/profile_response_dto.dart';
import 'package:notes_app/data/repository/profile/profile_repo.dart';
import 'package:notes_app/viewmodel/profile/profile_state.dart';

class ProfileViewmodel extends AsyncNotifier<ProfileState> {
  /// MARK: Variables
  final ProfileRepo _profileRepo = ProfileRepo();

  /// MARK: DATA
  var profileData = ProfileResponseDto();

  @override
  Future<ProfileState> build() async {
    return fetchUserDetails();
  }

  int getUserId() {
    return getIt<Preference>().getInt(PreferenceKeys.USER_ID) ?? 0;
  }

  Future<ProfileState> fetchUserDetails({int? id}) async {
    final int userId = id ?? getUserId();
    log("Fetching user details for userId: $userId");
    try {
      final response = await _profileRepo.getUserDetails(
        ProfileRequestDto(id: userId),
      );
      profileData = response;
      return ProfileState(profileData: profileData);
    } catch (e) {
      log("Error while fetching user details! $e");
      rethrow;
    }
  }

  Future<void> getUserDetails({int? id}) async {
    state = const AsyncLoading();
    try {
      final int userId = id ?? getUserId();
      log("Refetching user details for userId: $userId");
      final response = await _profileRepo.getUserDetails(
        ProfileRequestDto(id: userId),
      );
      profileData = response;
      state = AsyncData(ProfileState(profileData: profileData));
    } catch (e, st) {
      log("Error while refetching user details! $e");
      state = AsyncError(e.toString(), st);
    }
  }
}
