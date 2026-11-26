import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/note/update_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/update_task_request_dto.dart';
import 'package:notes_app/data/repository/home/home_repo.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';

import 'support/fake_server.dart';

/// FE-02: edits, status changes and deletes are saved locally first, survive
/// refreshes and restarts, and replay to the server in order.
const userId = 42;

class App {
  App(this.database, this.server) {
    sync = OfflineSyncService(
      client: server,
      database: database,
      minRetryDelay: const Duration(minutes: 1),
    );
    notes = NoteRepo(client: server, database: database, syncService: sync);
    home = HomeRepo(client: server, database: database, syncService: sync);
    tasks = TaskRepo(client: server, database: database, syncService: sync);
    reminders = ReminderRepo(client: server, database: database, syncService: sync);
  }

  final AppDatabase database;
  final FakeServer server;
  late final OfflineSyncService sync;
  late final NoteRepo notes;
  late final HomeRepo home;
  late final TaskRepo tasks;
  late final ReminderRepo reminders;

  /// Pull-to-refresh: fetch every list and merge it into the cache.
  Future<void> refresh() async {
    await home.getAllNotes(userId);
    await tasks.fetchAndCacheTasks(userId);
    await reminders.fetchAndCacheReminders(userId);
  }

  Future<void> goOnlineAndSync() {
    sync.setUserId(userId);
    return sync.requestSync();
  }

  Future<List<CachedNote>> visibleNotes() => database.getNotesForUser(userId);
  Future<List<CachedTask>> visibleTasks() => database.getTasksForUser(userId);
  Future<List<CachedReminder>> visibleReminders() => database.getRemindersForUser(userId);

  Future<void> close() async {
    await sync.dispose();
    await database.close();
  }
}

/// Writes fail as if offline; list requests still work, so refreshes run
/// while changes are queued.
Object? writesOffline(String call, Object? _) =>
    call.startsWith('get') ? null : throw FakeServer.offline();

void main() {
  late FakeServer server;
  late App app;

  /// Items that already exist on the server and in the cache.
  Future<void> seedServer() async {
    server.notes[1] = {'noteId': 1, 'userId': userId, 'title': 'Synced note', 'content': 'v1', 'category': 'General', 'pinned': false};
    server.tasks[2] = {'taskId': 2, 'userId': userId, 'title': 'Synced task', 'status': 'PENDING', 'isCompleted': false};
    server.reminders[3] = {'reminderId': 3, 'userId': userId, 'title': 'Synced reminder', 'remindAt': '2099-01-01T09:00:00', 'status': 'PENDING'};
    await app.refresh();
  }

  setUp(() {
    server = FakeServer();
    app = App(AppDatabase.forTesting(NativeDatabase.memory()), server);
  });

  tearDown(() => app.close());

  test('offline changes show at once, survive a refresh and reach the server', () async {
    await seedServer();
    server.onRequest = writesOffline;
    app.sync.setUserId(userId);

    await app.tasks.setTaskStatus(userId, 2, 'COMPLETED');
    await app.reminders.deleteReminder(userId, 3);
    await app.notes.updateNote(
      userId,
      UpdateNoteRequestDto(noteId: 1, title: 'Edited offline', content: 'v2', category: 'Work', pinned: true),
    );
    final unsyncedId = -await app.notes.enqueueNote(
      CreateNoteRequestDto(userId: userId, title: 'Unsynced', content: 'draft'),
    );
    await app.notes.updateNote(
      userId,
      UpdateNoteRequestDto(noteId: unsyncedId, title: 'Unsynced, edited', content: 'final', pinned: false),
    );
    final doomedId = -await app.notes.enqueueNote(
      CreateNoteRequestDto(userId: userId, title: 'Delete me', content: 'x'),
    );
    await app.notes.deleteNote(userId, doomedId);
    await app.sync.requestSync();

    Future<void> expectLocalState() async {
      expect((await app.visibleTasks()).single.status, 'COMPLETED');
      expect(await app.visibleReminders(), isEmpty);
      final notes = {for (final n in await app.visibleNotes()) n.title: n};
      expect(notes.keys, unorderedEquals(['Edited offline', 'Unsynced, edited']));
      expect(notes['Edited offline']!.pinned, isTrue);
      expect(notes['Unsynced, edited']!.content, 'final');
    }

    await expectLocalState();
    await app.refresh(); // the server still has the old values
    await expectLocalState();

    server.onRequest = null;
    await app.sync.requestSync();

    expect(server.tasks[2]!['status'], 'COMPLETED');
    expect(server.reminders, isEmpty);
    expect(server.notes[1]!['title'], 'Edited offline');
    expect(server.notes[1]!['pinned'], isTrue);
    final created = server.notes.values.where((n) => n['noteId'] != 1).toList();
    expect(created.map((n) => n['title']), ['Unsynced, edited'],
        reason: 'one create with the final values; the deleted draft never left');
    expect(created.single['content'], 'final');
    expect(server.count('createNote'), 1);
    expect(server.count('updateNote'), 1);
    expect(await app.database.getPendingMutations(userId), isEmpty);

    await app.refresh();
    await expectLocalState();
    expect((await app.visibleNotes()).every((n) => !n.isPending), isTrue);
  });

  test('changes survive an app restart', () async {
    final dir = await Directory.systemTemp.createTemp('daymark_restart');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/app.sqlite');
    await app.close();
    app = App(AppDatabase.forTesting(NativeDatabase(file)), server);
    await seedServer();
    server.onRequest = writesOffline;

    await app.tasks.setTaskStatus(userId, 2, 'REJECTED');
    await app.reminders.deleteReminder(userId, 3);
    await app.notes.updateNote(userId, UpdateNoteRequestDto(noteId: 1, title: 'Before restart', content: 'c', pinned: false));
    await app.close();

    // Restart: new database connection, new services.
    app = App(AppDatabase.forTesting(NativeDatabase(file)), server);
    expect((await app.visibleTasks()).single.status, 'REJECTED');
    expect(await app.visibleReminders(), isEmpty);
    expect((await app.visibleNotes()).single.title, 'Before restart');

    server.onRequest = null;
    await app.goOnlineAndSync();
    expect(server.tasks[2]!['status'], 'REJECTED');
    expect(server.reminders, isEmpty);
    expect(server.notes[1]!['title'], 'Before restart');
  });

  test('create offline, then edit, then complete: the server ends with the final values', () async {
    final localId = await app.tasks.enqueueTask(CreateTaskRequestDto(userId: userId, title: 'Draft'));
    await app.tasks.updateTask(userId, UpdateTaskRequestDto(taskId: -localId, title: 'Final title', priority: 'HIGH'));
    await app.tasks.setTaskStatus(userId, -localId, 'COMPLETED');

    await app.goOnlineAndSync();

    final task = server.tasks.values.single;
    expect(task['title'], 'Final title');
    expect(task['priority'], 'HIGH');
    expect(task['status'], 'COMPLETED');
    expect(task['isCompleted'], isTrue);
    expect(server.calls.where((c) => !c.startsWith('get')), ['createTask'],
        reason: 'edits to a never-sent create ride along with it');
  });

  test('changes replay in order; concurrent syncs send each change once', () async {
    await seedServer();
    await app.tasks.setTaskStatus(userId, 2, 'COMPLETED');
    await app.tasks.updateTask(userId, UpdateTaskRequestDto(taskId: 2, title: 'Renamed'));
    await app.tasks.setTaskStatus(userId, 2, 'PENDING');

    app.sync.setUserId(userId);
    await Future.wait([for (var i = 0; i < 5; i++) app.sync.requestSync()]);

    expect(server.calls.where((c) => !c.startsWith('get')),
        ['toggleTaskStatus', 'updateTask', 'toggleTaskStatus']);
    expect(server.tasks[2]!['title'], 'Renamed');
    expect(server.tasks[2]!['status'], 'PENDING');
  });

  test('a refused change is marked failed and does not block other items', () async {
    await seedServer();
    server.tasks[5] = {'taskId': 5, 'userId': userId, 'title': 'Other task', 'status': 'PENDING', 'isCompleted': false};
    await app.refresh();
    server.onRequest = (call, request) =>
        call == 'updateNote' ? throw FakeServer.status(400, 'Title must be at most 500 characters') : null;

    await app.notes.updateNote(userId, UpdateNoteRequestDto(noteId: 1, title: 'x' * 501, content: 'c', pinned: false));
    await app.notes.togglePin(userId, 1); // same note: must wait behind the refused change
    await app.tasks.setTaskStatus(userId, 5, 'COMPLETED');
    await app.reminders.updateReminderStatus(userId, 3, 'COMPLETED');
    await app.goOnlineAndSync();

    expect(server.tasks[5]!['status'], 'COMPLETED');
    expect(server.reminders[3]!['status'], 'COMPLETED');
    expect(server.count('updateNote'), 1, reason: 'the later pin waits behind the refused edit');
    final failures = await app.sync.watchFailures(userId).first;
    expect(failures.single.operation, 'update');
    expect(failures.single.entity, SyncEntity.note);
    expect(failures.single.lastError, 'Title must be at most 500 characters');

    // Discarding the refused edit lets the queue continue and a refresh
    // restores what the server has.
    await app.sync.discardFailed(failures.single);
    server.onRequest = null;
    await app.sync.requestSync();
    await app.refresh();
    final note = (await app.visibleNotes()).single;
    expect(note.isPending, isFalse);
    expect(server.notes[1]!['pinned'], isTrue);
  });

  test('deleting a synced item drops its earlier queued changes', () async {
    await seedServer();
    await app.tasks.setTaskStatus(userId, 2, 'COMPLETED');
    await app.tasks.updateTask(userId, UpdateTaskRequestDto(taskId: 2, title: 'Second'));
    await app.tasks.deleteTask(userId, 2);
    expect((await app.database.getPendingMutations(userId)).map((m) => m.op), ['delete']);

    await app.goOnlineAndSync();
    expect(server.calls.where((c) => !c.startsWith('get')), ['deleteTask']);
    expect(server.tasks, isEmpty);
    expect(await app.database.getPendingMutations(userId), isEmpty);
  });

  test('a transient failure stops the queue; the next sync resumes from there', () async {
    await seedServer();
    await app.reminders.updateReminderStatus(userId, 3, 'COMPLETED');
    await app.reminders.updateReminder(userId, UpdateReminderRequestDto(reminderId: 3, title: 'Renamed'));
    server.onRequest = (call, _) => call == 'updateReminder' ? throw FakeServer.offline() : null;

    await app.goOnlineAndSync();
    expect(server.reminders[3]!['status'], 'COMPLETED');
    expect(server.reminders[3]!['title'], 'Synced reminder');
    final queued = await app.database.getPendingMutations(userId);
    expect(queued.single.op, 'update');
    expect(queued.single.failed, isFalse);
    expect(app.sync.scheduledRetryDelay, isNotNull);

    server.onRequest = null;
    await app.sync.requestSync();
    expect(server.reminders[3]!['title'], 'Renamed');
    expect(await app.database.getPendingMutations(userId), isEmpty);
  });

  test('a delete stays hidden through a refresh until the server confirms', () async {
    await seedServer();
    server.onRequest = writesOffline;
    app.sync.setUserId(userId);
    await app.tasks.deleteTask(userId, 2);
    await app.sync.requestSync();

    await app.refresh();
    expect(await app.visibleTasks(), isEmpty);

    server.onRequest = null;
    await app.sync.requestSync();
    await app.refresh();
    expect(await app.visibleTasks(), isEmpty);
    expect(await app.database.select(app.database.cachedTasks).get(), isEmpty);
  });

  test('an update for an item the server no longer has is dropped', () async {
    await seedServer();
    server.notes.remove(1);
    await app.notes.updateNote(userId, UpdateNoteRequestDto(noteId: 1, title: 'Too late', content: 'c', pinned: false));

    await app.goOnlineAndSync();
    expect(await app.database.getPendingMutations(userId), isEmpty);
    expect(await app.sync.watchFailures(userId).first, isEmpty);

    await app.refresh();
    expect(await app.visibleNotes(), isEmpty);
  });

  test('an edit after a lost create response still reaches the server', () async {
    final localId = await app.notes.enqueueNote(
      CreateNoteRequestDto(userId: userId, title: 'Original', content: 'v1'),
    );
    server.onRequest = (call, _) => call == 'createNote' ? FakeServer.loseResponse : null;
    await app.goOnlineAndSync();
    expect(server.notes.values.single['title'], 'Original');

    // The app still thinks the note is unsynced; the server already has it.
    await app.notes.updateNote(userId, UpdateNoteRequestDto(noteId: -localId, title: 'Edited', content: 'v2', pinned: false));
    server.onRequest = null;
    await app.sync.requestSync();

    expect(server.notes, hasLength(1));
    expect(server.notes.values.single['title'], 'Edited');
    expect(server.notes.values.single['content'], 'v2');
    final note = (await app.visibleNotes()).single;
    expect(note.id, localId);
    expect(note.isPending, isFalse);
  });

  test('an edit made while the create is in flight is sent afterwards', () async {
    final localId = await app.notes.enqueueNote(
      CreateNoteRequestDto(userId: userId, title: 'First', content: 'v1'),
    );
    final release = Completer<void>();
    server.gate = release.future;
    app.sync.setUserId(userId);
    await pumpEventQueue();
    expect(server.count('createNote'), 1, reason: 'the create is in flight');

    await app.notes.updateNote(userId, UpdateNoteRequestDto(noteId: -localId, title: 'Second', content: 'v2', pinned: false));
    release.complete();
    server.gate = null;
    await app.sync.requestSync();

    expect(server.notes, hasLength(1));
    expect(server.notes.values.single['title'], 'Second');
  });

  test('a note deleted while its create is in flight is deleted on the server too', () async {
    final localId = await app.notes.enqueueNote(
      CreateNoteRequestDto(userId: userId, title: 'Short-lived', content: 'x'),
    );
    final release = Completer<void>();
    server.gate = release.future;
    app.sync.setUserId(userId);
    await pumpEventQueue();

    await app.notes.deleteNote(userId, -localId);
    release.complete();
    server.gate = null;
    await app.sync.requestSync();

    expect(server.notes, isEmpty);
    expect(await app.visibleNotes(), isEmpty);
    expect(await app.database.getPendingMutations(userId), isEmpty);
  });

  test('discarding a refused delete shows the item again', () async {
    await seedServer();
    server.onRequest = (call, _) => call == 'deleteReminder' ? throw FakeServer.status(403) : null;
    await app.reminders.deleteReminder(userId, 3);
    await app.goOnlineAndSync();
    expect(await app.visibleReminders(), isEmpty);

    final failure = (await app.sync.watchFailures(userId).first).single;
    expect(failure.operation, 'delete');
    await app.sync.discardFailed(failure);

    expect((await app.visibleReminders()).single.title, 'Synced reminder');
    expect(server.reminders, hasLength(1));
  });

  test('editing a note that does not exist fails instead of calling the server', () async {
    await expectLater(
      app.notes.updateNote(userId, UpdateNoteRequestDto(noteId: -999, title: 't', content: 'c')),
      throwsStateError,
    );
    expect(server.calls, isEmpty);
  });
}
