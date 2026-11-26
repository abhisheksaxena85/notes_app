import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/repository/profile/profile_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/res/api_error.dart';

/// Simulates the backend answering with a real 4xx status (BE-03): Dio throws.
class NotFoundApiClient extends ApiClient {
  NotFoundApiClient() : super(dioClient: DioClient(Dio()));

  DioException _notFound(String path, String message) {
    final options = RequestOptions(path: path);
    return DioException.badResponse(
      statusCode: 404,
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 404,
        data: {'success': false, 'message': message, 'data': null},
      ),
    );
  }

  @override
  Future<Response> deleteNote(int id) async =>
      throw _notFound('/notes/delete-note', 'Note not found');

  @override
  Future<Response> deleteUser(int userId) async =>
      throw _notFound('/auth/delete-user', 'User not found');
}

void main() {
  late AppDatabase database;
  late NotFoundApiClient client;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    client = NotFoundApiClient();
  });

  tearDown(() async {
    await database.close();
  });

  test('deleteNote on 404 drops the stale cached note and surfaces "Note not found"', () async {
    final repo = NoteRepo(
      client: client,
      database: database,
      syncService: OfflineSyncService(client: client, database: database),
    );
    await database.saveServerNote(
      CachedNotesCompanion.insert(
        userId: 7,
        serverId: const Value(55),
        title: 'Gone on server',
        content: 'x',
      ),
    );

    Object? caught;
    try {
      await repo.deleteNote(55);
    } catch (e) {
      caught = e;
    }

    expect(caught, isA<DioException>());
    expect(userMessage(caught!), 'Note not found');
    expect(await database.getNoteByServerId(7, 55), isNull);
  });

  test('deleteUser on 404 is treated as already deleted and clears local data', () async {
    final repo = ProfileRepo(client: client, database: database);
    await database.saveProfile(
      CachedProfilesCompanion.insert(userId: const Value(7), name: const Value('A')),
    );

    await repo.deleteUser(7);

    expect(await database.getProfile(7), isNull);
  });
}
