import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:notes_app/data/local/database/task_database_mapper.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';

import 'support/fake_server.dart';

/// FE-03: one sync entry point, idempotent creates, per-item error isolation.
void main() {
  const userId = 42;
  late AppDatabase database;
  late FakeServer server;
  late OfflineSyncService sync;
  late NoteRepo noteRepo;
  late TaskRepo taskRepo;
  late ReminderRepo reminderRepo;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    server = FakeServer();
    sync = OfflineSyncService(
      client: server,
      database: database,
      // Long enough that no automatic retry fires during a test.
      minRetryDelay: const Duration(minutes: 1),
      maxRetryDelay: const Duration(minutes: 8),
    );
    noteRepo = NoteRepo(client: server, database: database, syncService: sync);
    taskRepo = TaskRepo(client: server, database: database, syncService: sync);
    reminderRepo =
        ReminderRepo(client: server, database: database, syncService: sync);
  });

  tearDown(() async {
    await sync.dispose();
    await database.close();
  });

  Future<int> queueNote(String title) => noteRepo.enqueueNote(
        CreateNoteRequestDto(userId: userId, title: title, content: 'Body of $title'),
      );

  Future<int> queueTask(String title) =>
      taskRepo.enqueueTask(CreateTaskRequestDto(userId: userId, title: title));

  Future<int> queueReminder(String title) => reminderRepo.enqueueReminder(
        CreateReminderRequestDto(
          userId: userId,
          title: title,
          remindAt: '2099-01-01T09:00:00',
        ),
      );

  test('five concurrent requestSync calls upload one queued item exactly once',
      () async {
    await queueNote('only');
    final release = Completer<void>();
    server.gate = release.future;

    sync.setUserId(userId); // starts a pass, which waits on the gate
    final calls = [for (var i = 0; i < 5; i++) sync.requestSync()];
    await pumpEventQueue();
    release.complete();
    await Future.wait(calls);

    expect(server.count('createNote'), 1);
    expect(server.notes, hasLength(1));
    expect(await database.getPendingNotes(userId), isEmpty);
  });

  test('every queued create carries a client id, on the row and in the upload',
      () async {
    final localId = await queueTask('with id');
    final pending = (await database.getPendingTasks(userId)).single;
    final cached = (await database.getTasksForUser(userId)).single;

    expect(pending.clientId, isNotNull);
    expect(cached.id, localId);
    expect(cached.clientId, pending.clientId);
    expect(jsonDecode(pending.payload)['clientId'], pending.clientId);

    sync.setUserId(userId);
    await sync.requestSync();
    expect(server.tasks.values.single['clientId'], pending.clientId);
  });

  test(
      'a create whose response is lost is not duplicated when it is retried, '
      'even if a refresh cached the server copy in between', () async {
    final localId = await queueTask('lost response');
    server.onRequest =
        (call, _) => call == 'createTask' ? FakeServer.loseResponse : null;

    sync.setUserId(userId);
    await sync.requestSync();
    expect(server.tasks, hasLength(1), reason: 'the server created it');
    expect(await database.getPendingTasks(userId), hasLength(1),
        reason: 'the app never saw the answer, so it is still queued');
    expect(sync.scheduledRetryDelay, const Duration(minutes: 1));

    // A refresh before the retry caches the server copy as well.
    final serverId = server.tasks.keys.single;
    await database.replaceServerTasks(userId, [
      TaskDatabaseMapper.fromTaskItem(
        userId,
        TaskItem(taskId: serverId, title: 'lost response'),
      ),
    ]);

    server.onRequest = null;
    await sync.requestSync();

    expect(server.count('createTask'), 2);
    expect(server.tasks, hasLength(1), reason: 'the retry reused the client id');
    expect(await database.getPendingTasks(userId), isEmpty);
    final cached = await database.getTasksForUser(userId);
    expect(cached, hasLength(1));
    expect(cached.single.id, localId, reason: 'the local row keeps its id');
    expect(cached.single.serverId, serverId);
    expect(sync.scheduledRetryDelay, isNull, reason: 'backoff resets on success');
  });

  test(
      'queue [bad note, good note, good task, good reminder]: the good ones '
      'sync and the bad one is marked failed', () async {
    await queueNote('bad');
    await queueNote('good');
    await queueTask('good task');
    await queueReminder('good reminder');
    server.onRequest = (call, request) =>
        request is Map && request['title'] == 'bad' ? throw FakeServer.status(400, 'Too long') : null;

    sync.setUserId(userId);
    await sync.requestSync();

    expect([for (final n in server.notes.values) n['title']], ['good']);
    expect(server.tasks, hasLength(1));
    expect(server.reminders, hasLength(1));
    expect(await database.getPendingTasks(userId), isEmpty);
    expect(await database.getPendingReminders(userId), isEmpty);

    final failures = await sync.watchFailures(userId).first;
    expect(failures, hasLength(1));
    expect(failures.single.entity, SyncEntity.note);
    expect(failures.single.title, 'bad');
    expect(failures.single.lastError, 'Too long');
    expect(failures.single.attempts, 1);
    expect(sync.scheduledRetryDelay, isNull,
        reason: 'a refused item is not retried automatically');

    // A later sync does not send the failed item again.
    await sync.requestSync();
    expect(server.count('createNote'), 2);
  });

  test('retrying a failed item sends it again; discarding drops it locally',
      () async {
    await queueNote('retry me');
    await queueTask('discard me');
    server.onRequest = (call, _) => throw FakeServer.status(422);
    sync.setUserId(userId);
    await sync.requestSync();
    final failures = await sync.watchFailures(userId).first;
    expect(failures, hasLength(2));

    server.onRequest = null;
    await sync.retryFailed(
      failures.where((f) => f.entity == SyncEntity.note).toList(),
    );
    expect(server.notes, hasLength(1));

    await sync.discardFailed(
      failures.singleWhere((f) => f.entity == SyncEntity.task),
    );
    expect(await database.getPendingTasks(userId), isEmpty);
    expect(await database.getTasksForUser(userId), isEmpty);
    expect(await sync.watchFailures(userId).first, isEmpty);
    expect(server.tasks, isEmpty);
  });

  test(
      'a transient error stops only that queue and backs off exponentially; '
      'other queues still sync', () async {
    await queueNote('first');
    await queueNote('second');
    await queueTask('task');
    server.onRequest = (call, _) => call == 'createNote' ? throw FakeServer.status(503) : null;

    sync.setUserId(userId);
    await sync.requestSync();

    expect(server.count('createNote'), 1, reason: 'the note queue stops at the first');
    expect(server.tasks, hasLength(1));
    final queued = await database.getPendingNotes(userId);
    expect(queued, hasLength(2));
    expect(queued.first.failed, isFalse, reason: '503 is transient, not a refusal');
    expect(queued.first.attempts, 1);
    expect(sync.scheduledRetryDelay, const Duration(minutes: 1));

    await sync.requestSync();
    expect(sync.scheduledRetryDelay, const Duration(minutes: 2));
    server.onRequest = (call, _) => call == 'createNote' ? throw FakeServer.offline() : null;
    await sync.requestSync();
    expect(sync.scheduledRetryDelay, const Duration(minutes: 4));
    await sync.requestSync();
    await sync.requestSync();
    expect(sync.scheduledRetryDelay, const Duration(minutes: 8), reason: 'capped');

    server.onRequest = null;
    await sync.requestSync();
    expect(server.notes, hasLength(2));
    expect(sync.scheduledRetryDelay, isNull);
  });

  test('while backing off, app resume does not trigger an immediate retry',
      () async {
    await queueNote('note');
    server.onRequest = (call, _) => throw FakeServer.offline();
    sync.setUserId(userId);
    await sync.requestSync();
    final callsAfterFailure = server.calls.length;

    sync.onAppResumed();
    await pumpEventQueue();
    expect(server.calls.length, callsAfterFailure);
    expect(sync.scheduledRetryDelay, isNotNull);
  });

  test('with no retry pending, app resume syncs right away', () async {
    sync.setUserId(userId);
    await sync.requestSync();
    // Queued straight into the database, so only the resume can upload it.
    await database.enqueueNote(
      userId: userId,
      title: 'queued',
      content: 'x',
      category: 'General',
      pinned: false,
      clientId: 'resume-client-id',
      payload: jsonEncode({'userId': userId, 'title': 'queued', 'content': 'x'}),
    );

    sync.onAppResumed();
    await pumpEventQueue(times: 200);

    expect(server.count('createNote'), 1);
  });

  test('payloads queued before client ids existed are sent with the row id',
      () async {
    await database.enqueueNote(
      userId: userId,
      title: 'legacy',
      content: 'queued by an old build',
      category: 'General',
      pinned: false,
      clientId: 'row-client-id',
      payload: jsonEncode({'userId': userId, 'title': 'legacy', 'content': 'x'}),
    );

    sync.setUserId(userId);
    await sync.requestSync();
    expect(server.notes.values.single['clientId'], 'row-client-id');
  });
}
