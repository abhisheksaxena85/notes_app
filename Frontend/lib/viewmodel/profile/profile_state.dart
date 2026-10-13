class ProfileState {
  final List<String> drivesList;

  ProfileState({this.drivesList = const []});

  ProfileState copyWith({List<String>? drivesList, bool? isLoading}) {
    return ProfileState(drivesList: drivesList ?? this.drivesList);
  }
}
