import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';

class HomeState {
  final GetAllNotesResponseDto? notesData;

  const HomeState({
    this.notesData,
  });

  HomeState copyWith({
    GetAllNotesResponseDto? notesData,
  }) {
    return HomeState(
      notesData: notesData ?? this.notesData,
    );
  }
}
