import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/note_database_mapper.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';

class HomeRepo {
  final ApiClient client;
  final AppDatabase database;
  final OfflineSyncService syncService;

  HomeRepo({
    required this.client,
    required this.database,
    required this.syncService,
  });

  Future<GetAllNotesResponseDto> getCachedNotes(int userId) async {
    final notes = await database.getNotesForUser(userId);
    return GetAllNotesResponseDto(
      success: true,
      data: notes.map(NoteDatabaseMapper.toNoteItem).toList(),
    );
  }

  Stream<List<NoteItem>> watchNotes(int userId) {
    return database
        .watchNotesForUser(userId)
        .map((notes) => notes.map(NoteDatabaseMapper.toNoteItem).toList());
  }

  /// Refreshes the cache from the server. Runs while no sync pass is
  /// running, so the merge can't undo a change that was just replayed.
  Future<GetAllNotesResponseDto> getAllNotes(int id) {
    return syncService.runExclusive(() => _fetchAndMerge(id));
  }

  Future<GetAllNotesResponseDto> _fetchAndMerge(int id) async {
    try {
      final response = await client.getAllNotes(id);
      if (response.statusCode != 200) {
        return await getCachedNotes(id);
      }

      final notesResponse = GetAllNotesResponseDto.fromJson(response.data);
      if (notesResponse.success != true) {
        return await getCachedNotes(id);
      }

      final notes = notesResponse.data ?? [];
      final noteRows = notes
          .map((note) => NoteDatabaseMapper.fromNoteItem(id, note))
          .toList();
      await database.replaceServerNotes(id, noteRows);
      return notesResponse;
    } catch (_) {
      return await getCachedNotes(id);
    }
  }
}
