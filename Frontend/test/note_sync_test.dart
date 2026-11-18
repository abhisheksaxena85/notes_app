import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient(this.createNoteResponse) : super(dioClient: DioClient(Dio()));

  Map<String, dynamic> createNoteResponse;

  @override
  Future<Response> createNote(CreateNoteRequestDto requestDto) async {
    return Response(
      requestOptions: RequestOptions(path: '/notes'),
      statusCode: 200,
      data: createNoteResponse,
    );
  }
}

void main() {
  late AppDatabase database;
  late FakeApiClient client;
  late NoteRepo repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    client = FakeApiClient({'success': false, 'message': 'Not accepted'});
    repository = NoteRepo(client: client, database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'keeps queued note after API failure and removes it after success',
    () async {
      final localId = await repository.enqueueNote(
        CreateNoteRequestDto(
          userId: 42,
          title: 'Queued note',
          content: 'Pending',
          category: 'General',
          pinned: false,
        ),
      );

      await expectLater(
        repository.syncQueuedNotes(42),
        throwsA(isA<StateError>()),
      );
      expect(await database.getPendingNotes(42), hasLength(1));

      client.createNoteResponse = {
        'success': true,
        'data': {'noteId': 99},
      };
      await repository.syncQueuedNotes(42);

      expect(await database.getPendingNotes(42), isEmpty);
      final note = await database.getNote(42, 99);
      expect(note?.id, localId);
      expect(note?.isPending, isFalse);
    },
  );
}
