import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/note/update_note_request_dto.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/note_data_transfer_service.dart';

class FakeExportImportApiClient extends ApiClient {
  FakeExportImportApiClient() : super(dioClient: DioClient(Dio()));

  final List<CreateNoteRequestDto> createdNotes = [];
  final List<UpdateNoteRequestDto> updatedNotes = [];
  int nextServerId = 500;
  bool shouldFailCreation = false;

  @override
  Future<Response> createNote(CreateNoteRequestDto requestDto) async {
    if (shouldFailCreation) {
      return Response(
        requestOptions: RequestOptions(path: '/notes/create-note'),
        statusCode: 500,
        data: {'success': false, 'message': 'Server offline'},
      );
    }
    createdNotes.add(requestDto);
    final id = nextServerId++;
    return Response(
      requestOptions: RequestOptions(path: '/notes/create-note'),
      statusCode: 200,
      data: {
        'success': true,
        'message': 'Note created successfully',
        'data': {'noteId': id},
      },
    );
  }

  @override
  Future<Response> updateNote(UpdateNoteRequestDto requestDto) async {
    updatedNotes.add(requestDto);
    return Response(
      requestOptions: RequestOptions(path: '/notes/update-note'),
      statusCode: 200,
      data: {
        'success': true,
        'message': 'Note updated successfully',
        'data': {
          'noteId': requestDto.noteId,
          'title': requestDto.title,
          'content': requestDto.content,
          'category': requestDto.category,
          'pinned': requestDto.pinned,
          'tags': requestDto.tags,
        },
      },
    );
  }
}

void main() {
  group('NoteDataTransferService - Format & Parsing Tests', () {
    test('CSV export escapes quotes, commas, and newlines properly', () {
      final items = [
        const NoteExportItem(
          noteId: 1,
          title: 'Meeting, "Urgent"',
          content: 'Line 1\nLine 2, with comma',
          category: 'Work',
          pinned: true,
          tags: 'work, roadmap',
          createdAt: '2026-11-18T10:00:00',
        ),
      ];

      final csv = NoteDataTransferService.exportNotes(items, NoteExportFormat.csv);
      expect(csv, contains('Title,Content,Category,Pinned,Tags,Created At,Updated At'));
      expect(csv, contains('"Meeting, ""Urgent"""'));
      expect(csv, contains('"Line 1\nLine 2, with comma"'));
      expect(csv, contains('"work, roadmap"'));
      expect(csv, contains('true'));
    });

    test('CSV parse correctly parses multiline fields and escaped quotes (RFC 4180)', () {
      const csvInput = '''Title,Content,Category,Pinned,Tags,Created At,Updated At
"Project, ""Alpha""","Feature list:
- Item 1
- Item 2, revised",Projects,true,"dev, alpha",2026-11-18T12:00:00,
Simple Note,Just plain content,General,false,,,
''';

      final parsed = NoteDataTransferService.parseNotes(csvInput, NoteExportFormat.csv);
      expect(parsed, hasLength(2));

      expect(parsed[0].title, 'Project, "Alpha"');
      expect(parsed[0].content, 'Feature list:\n- Item 1\n- Item 2, revised');
      expect(parsed[0].category, 'Projects');
      expect(parsed[0].pinned, isTrue);
      expect(parsed[0].tags, 'dev, alpha');
      expect(parsed[0].createdAt, '2026-11-18T12:00:00');

      expect(parsed[1].title, 'Simple Note');
      expect(parsed[1].content, 'Just plain content');
      expect(parsed[1].category, 'General');
      expect(parsed[1].pinned, isFalse);
    });

    test('TXT export and parse round-trip preserves note data', () {
      final original = [
        const NoteExportItem(
          title: 'Grocery List',
          content: 'Milk\nBread\nEggs',
          category: 'Personal',
          pinned: false,
          tags: 'food, shopping',
          createdAt: '2026-11-18T08:00:00',
        ),
        const NoteExportItem(
          title: 'Ideas',
          content: 'Build AI assistant plugin',
          category: 'Work',
          pinned: true,
          tags: 'ai, productivity',
        ),
      ];

      final txt = NoteDataTransferService.exportNotes(original, NoteExportFormat.txt);
      expect(txt, contains('Title: Grocery List'));
      expect(txt, contains('Category: Personal'));
      expect(txt, contains('Milk\nBread\nEggs'));
      expect(txt, contains('Title: Ideas'));

      final parsed = NoteDataTransferService.parseNotes(txt, NoteExportFormat.txt);
      expect(parsed, hasLength(2));
      expect(parsed[0].title, 'Grocery List');
      expect(parsed[0].content, 'Milk\nBread\nEggs');
      expect(parsed[0].category, 'Personal');
      expect(parsed[0].tags, 'food, shopping');
      expect(parsed[0].createdAt, '2026-11-18T08:00:00');

      expect(parsed[1].title, 'Ideas');
      expect(parsed[1].content, 'Build AI assistant plugin');
      expect(parsed[1].category, 'Work');
      expect(parsed[1].pinned, isTrue);
    });

    test('JSON export and parse handles versioned export payload', () {
      final original = [
        const NoteExportItem(
          noteId: 101,
          title: 'Architecture Spec',
          content: 'Clean architecture with Drift and Riverpod',
          category: 'Engineering',
          pinned: true,
          tags: 'drift, flutter',
        ),
      ];

      final jsonString = NoteDataTransferService.exportNotes(
        original,
        NoteExportFormat.json,
        userId: 42,
      );

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['exportVersion'], 1);
      expect(decoded['userId'], 42);
      expect(decoded['totalNotes'], 1);

      final parsed = NoteDataTransferService.parseNotes(jsonString, NoteExportFormat.json);
      expect(parsed, hasLength(1));
      expect(parsed[0].noteId, 101);
      expect(parsed[0].title, 'Architecture Spec');
      expect(parsed[0].content, 'Clean architecture with Drift and Riverpod');
      expect(parsed[0].category, 'Engineering');
      expect(parsed[0].pinned, isTrue);
      expect(parsed[0].tags, 'drift, flutter');
    });

    test('Format detection detects JSON, CSV, and TXT correctly', () {
      expect(
        NoteDataTransferService.detectFormat('{"notes": []}'),
        NoteExportFormat.json,
      );
      expect(
        NoteDataTransferService.detectFormat('[{"title": "test"}]'),
        NoteExportFormat.json,
      );
      expect(
        NoteDataTransferService.detectFormat('Title,Content,Category\nTest,Body,General'),
        NoteExportFormat.csv,
      );
      expect(
        NoteDataTransferService.detectFormat('==================================================\nTitle: Test\n--------------------------------------------------\nBody'),
        NoteExportFormat.txt,
      );
    });

    test('exportSingleNote formats individually for CSV, TXT, and JSON', () {
      const note = NoteExportItem(
        noteId: 7,
        title: 'Single Note',
        content: 'Body text',
        category: 'Personal',
        pinned: true,
      );

      final csv = NoteDataTransferService.exportSingleNote(note, NoteExportFormat.csv);
      expect(csv, contains('Single Note,Body text,Personal,true'));

      final txt = NoteDataTransferService.exportSingleNote(note, NoteExportFormat.txt);
      expect(txt, contains('Title: Single Note'));
      expect(txt, contains('Body text'));

      final jsonStr = NoteDataTransferService.exportSingleNote(note, NoteExportFormat.json);
      expect(jsonStr, contains('"title": "Single Note"'));
    });
  });

  group('NoteRepo Import & Server Sync Integration Tests', () {
    late AppDatabase database;
    late FakeExportImportApiClient client;
    late NoteRepo repository;
    late OfflineSyncService syncService;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      client = FakeExportImportApiClient();
      syncService = OfflineSyncService(client: client, database: database)
        ..setUserId(42);
      repository = NoteRepo(
        client: client,
        database: database,
        syncService: syncService,
      );
    });

    tearDown(() async {
      await syncService.dispose();
      await database.close();
    });

    test('imports new notes into local DB and syncs them to server via API', () async {
      final itemsToImport = [
        const NoteExportItem(
          title: 'Imported Note 1',
          content: 'Content 1',
          category: 'Work',
          pinned: true,
          tags: 'tag1, tag2',
        ),
        const NoteExportItem(
          title: 'Imported Note 2',
          content: 'Content 2',
          category: 'Personal',
          pinned: false,
        ),
      ];

      final result = await repository.importNotes(
        userId: 42,
        notes: itemsToImport,
      );

      expect(result.importedCount, 2);
      expect(result.duplicateCount, 0);
      expect(result.syncedToServer, isTrue);
      expect(client.createdNotes, hasLength(2));
      expect(client.createdNotes[0].title, 'Imported Note 1');
      expect(client.createdNotes[1].title, 'Imported Note 2');

      // Notes should now be in local database with server IDs assigned and isPending = false
      final localNotes = await database.getNotesForUser(42);
      expect(localNotes, hasLength(2));
      expect(localNotes.every((n) => !n.isPending && n.serverId != null), isTrue);

      // Pending queue should be empty after successful sync
      final pending = await database.getPendingNotes(42);
      expect(pending, isEmpty);
    });

    test('deduplicates identical notes when re-imported into local DB', () async {
      final itemsToImport = [
        const NoteExportItem(
          title: 'Unique Note',
          content: 'Unique content here',
          category: 'Work',
          pinned: false,
          tags: 'original',
        ),
      ];

      // First import
      final firstResult = await repository.importNotes(
        userId: 42,
        notes: itemsToImport,
      );
      expect(firstResult.importedCount, 1);
      expect(firstResult.duplicateCount, 0);
      expect(client.createdNotes, hasLength(1));

      // Re-import the exact same data
      final secondResult = await repository.importNotes(
        userId: 42,
        notes: itemsToImport,
      );
      expect(secondResult.importedCount, 0);
      expect(secondResult.duplicateCount, 1);
      // Server should NOT receive a duplicate create call
      expect(client.createdNotes, hasLength(1));

      final localNotes = await database.getNotesForUser(42);
      expect(localNotes, hasLength(1));
    });

    test('updates existing note if serverId matches and content changed', () async {
      // 1. Initial import
      final firstResult = await repository.importNotes(
        userId: 42,
        notes: [
          const NoteExportItem(
            title: 'Initial Title',
            content: 'Initial Content',
            category: 'Work',
            pinned: false,
          ),
        ],
      );
      expect(firstResult.importedCount, 1);
      final localNotes = await database.getNotesForUser(42);
      final assignedServerId = localNotes.first.serverId!;

      // 2. Import updated version with matching serverId
      final updateImport = [
        NoteExportItem(
          noteId: assignedServerId,
          title: 'Revised Title',
          content: 'Revised Content with more detail',
          category: 'Work',
          pinned: true,
          tags: 'updated',
        ),
      ];

      final updateResult = await repository.importNotes(
        userId: 42,
        notes: updateImport,
      );

      expect(updateResult.importedCount, 0);
      expect(updateResult.updatedCount, 1);
      expect(updateResult.duplicateCount, 0);
      expect(client.updatedNotes, hasLength(1));
      expect(client.updatedNotes.first.title, 'Revised Title');

      final refreshedNotes = await database.getNotesForUser(42);
      expect(refreshedNotes.first.title, 'Revised Title');
      expect(refreshedNotes.first.content, 'Revised Content with more detail');
      expect(refreshedNotes.first.pinned, isTrue);
    });

    test('handles offline/server failure gracefully: keeps imported notes in local DB and queue', () async {
      client.shouldFailCreation = true;

      final items = [
        const NoteExportItem(
          title: 'Offline Import Note',
          content: 'Stored in SQLite while server is down',
          category: 'Offline',
        ),
      ];

      final result = await repository.importNotes(userId: 42, notes: items);

      expect(result.importedCount, 1);
      expect(result.syncedToServer, isFalse);

      // Note must be preserved in local database as pending
      final localNotes = await database.getNotesForUser(42);
      expect(localNotes, hasLength(1));
      expect(localNotes.first.title, 'Offline Import Note');
      expect(localNotes.first.isPending, isTrue);

      // Note must be in pendingNotes table ready for background sync
      final pendingNotes = await database.getPendingNotes(42);
      expect(pendingNotes, hasLength(1));
      expect(pendingNotes.first.payload, contains('Offline Import Note'));
    });
  });
}
