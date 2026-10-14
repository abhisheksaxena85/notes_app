import 'package:notes_app/data/network/dto/response/profile/profile_response_dto.dart';

class ProfileState {
  final ProfileResponseDto? profileData;

  const ProfileState({this.profileData});

  ProfileState copyWith({
    ProfileResponseDto? profileData,
  }) {
    return ProfileState(
      profileData: profileData ?? this.profileData,
    );
  }
}
