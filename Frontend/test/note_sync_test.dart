import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';

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

/// Accepts every note except the one titled "rejected", which gets the 400 the
/// backend sends for an oversized note (BE-01).
class SelectiveApiClient extends ApiClient {
  SelectiveApiClient() : super(dioClient: DioClient(Dio()));

  final List<String> createdNotes = [];
  final List<String> createdTasks = [];
  int _nextId = 100;

  @override
  Future<Response> createNote(CreateNoteRequestDto requestDto) async {
    final options = RequestOptions(path: '/notes/create-note');
    if (requestDto.title == 'rejected') {
      throw DioException.badResponse(
        statusCode: 400,
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {'success': false, 'message': 'Content must be at most 100000 characters'},
        ),
      );
    }
    createdNotes.add(requestDto.title!);
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: {'success': true, 'data': {'noteId': _nextId++}},
    );
  }

  @override
  Future<Response> createTask(CreateTaskRequestDto requestDto) async {
    createdTasks.add(requestDto.title);
    return Response(
      requestOptions: RequestOptions(path: '/tasks/create-task'),
      statusCode: 201,
      data: {'success': true, 'data': {'taskId': _nextId++}},
    );
  }
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  CreateNoteRequestDto note(String title) => CreateNoteRequestDto(
        userId: 42,
        title: title,
        content: 'Body of $title',
        category: 'General',
        pinned: false,
      );

  test(
    'keeps a rejected note queued without throwing, and removes it after success',
    () async {
      final client = FakeApiClient({'success': false, 'message': 'Not accepted'});
      final repository = NoteRepo(client: client, database: database);
      final localId = await repository.enqueueNote(note('Queued note'));

      await repository.syncQueuedNotes(42);
      expect(await database.getPendingNotes(42), hasLength(1));

      client.createNoteResponse = {
        'success': true,
        'data': {'noteId': 99},
      };
      await repository.syncQueuedNotes(42);

      expect(await database.getPendingNotes(42), isEmpty);
      final synced = await database.getNote(42, 99);
      expect(synced?.id, localId);
      expect(synced?.isPending, isFalse);
    },
  );

  test(
    'BE-01: a rejected note does not block the notes queued after it or the task queue',
    () async {
      final client = SelectiveApiClient();
      final noteRepo = NoteRepo(client: client, database: database);
      final taskRepo = TaskRepo(client: client, database: database);
      final service = OfflineSyncService(
        noteRepo: noteRepo,
        taskRepo: taskRepo,
        connectionChecker: InternetConnectionChecker.createInstance(),
      );

      await noteRepo.enqueueNote(note('first'));
      await noteRepo.enqueueNote(note('rejected'));
      await noteRepo.enqueueNote(note('third'));
      await taskRepo.enqueueTask(CreateTaskRequestDto(userId: 42, title: 'task'));

      service.setUserId(42);
      await service.syncPendingAll();

      expect(client.createdNotes, ['first', 'third']);
      expect(client.createdTasks, ['task']);
      final stillQueued = await database.getPendingNotes(42);
      expect(stillQueued, hasLength(1));
      expect(stillQueued.single.payload, contains('rejected'));
      expect(await database.getPendingTasks(42), isEmpty);
    },
  );
}
