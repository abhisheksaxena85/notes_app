import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/note_database_mapper.dart';
import 'package:notes_app/data/local/database/reminder_database_mapper.dart';
import 'package:notes_app/data/local/database/task_database_mapper.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';

/// FE-04: server rows are upserted by (userId, serverId) and a refresh is a
/// merge that keeps local row ids.
void main() {
  const userId = 42;
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  CachedNotesCompanion serverNote(int id, String title, {String? clientId}) =>
      NoteDatabaseMapper.fromNoteItem(
        userId,
        NoteItem(noteId: id, title: title, content: "Body of $title", clientId: clientId),
      );

  CachedRemindersCompanion serverReminder(int id, String title) =>
      ReminderDatabaseMapper.fromReminderItem(
        userId,
        ReminderItem(reminderId: id, title: title, remindAt: '2099-01-01T09:00:00'),
      );

  CachedTasksCompanion serverTask(int id, String title) =>
      TaskDatabaseMapper.fromTaskItem(userId, TaskItem(taskId: id, title: title));

  group('saveServer*', () {
    test('saveServerNote twice with the same serverId leaves one updated row',
        () async {
      await database.saveServerNote(serverNote(5, 'Before'));
      final firstId = (await database.getNoteByServerId(userId, 5))!.id;

      await database.saveServerNote(serverNote(5, 'After'));

      final notes = await database.getNotesForUser(userId);
      expect(notes, hasLength(1));
      expect(notes.single.title, 'After');
      expect(notes.single.id, firstId);
    });

    test('the same serverId for another user is a different row', () async {
      await database.saveServerNote(serverNote(5, 'Mine'));
      await database.saveServerNote(
        NoteDatabaseMapper.fromNoteItem(7, NoteItem(noteId: 5, title: 'Theirs', content: '')),
      );
      expect(await database.getNotesForUser(userId), hasLength(1));
      expect(await database.getNotesForUser(7), hasLength(1));
    });
  });

  group('replaceServer* merges', () {
    test('two refreshes with the same reminders keep the same local ids',
        () async {
      final list = [serverReminder(1, 'One'), serverReminder(2, 'Two')];
      await database.replaceServerReminders(userId, list);
      final before = {
        for (final r in await database.getRemindersForUser(userId)) r.serverId: r.id,
      };

      await database.replaceServerReminders(userId, list);
      final after = {
        for (final r in await database.getRemindersForUser(userId)) r.serverId: r.id,
      };

      expect(after, before);
    });

    test('changed server values are applied in place', () async {
      await database.replaceServerTasks(userId, [serverTask(3, 'Old title')]);
      final id = (await database.getTasksForUser(userId)).single.id;

      await database.replaceServerTasks(userId, [serverTask(3, 'New title')]);

      final task = (await database.getTasksForUser(userId)).single;
      expect(task.id, id);
      expect(task.title, 'New title');
    });

    test('an item missing from the server list is deleted locally', () async {
      await database.replaceServerNotes(userId, [serverNote(1, 'Kept'), serverNote(2, 'Gone')]);
      await database.replaceServerNotes(userId, [serverNote(1, 'Kept')]);

      final notes = await database.getNotesForUser(userId);
      expect(notes.map((n) => n.serverId), [1]);
    });

    test('a synced item with pending local changes is neither overwritten nor deleted',
        () async {
      await database.replaceServerTasks(userId, [serverTask(3, 'Server'), serverTask(4, 'Edited')]);
      final edited = (await database.getTasksForUser(userId)).singleWhere((t) => t.serverId == 4);
      await (database.update(database.cachedTasks)..where((t) => t.id.equals(edited.id))).write(
        const CachedTasksCompanion(title: Value('Local edit'), isPending: Value(true)),
      );

      // Server list no longer has 4 and has a stale copy of it.
      await database.replaceServerTasks(userId, [serverTask(3, 'Server')]);
      var tasks = await database.getTasksForUser(userId);
      expect(tasks.singleWhere((t) => t.serverId == 4).title, 'Local edit');

      await database.replaceServerTasks(userId, [serverTask(3, 'Server'), serverTask(4, 'Stale')]);
      tasks = await database.getTasksForUser(userId);
      expect(tasks.singleWhere((t) => t.serverId == 4).title, 'Local edit');
    });

    test('local-only rows (no serverId) are never touched', () async {
      final localId = await database.enqueueNote(
        userId: userId,
        title: 'Offline',
        content: 'x',
        category: 'General',
        pinned: false,
        clientId: 'local-client',
        payload: '{}',
      );

      await database.replaceServerNotes(userId, [serverNote(1, 'Server')]);
      await database.replaceServerNotes(userId, const []);

      final notes = await database.getNotesForUser(userId);
      expect(notes.map((n) => n.id), [localId]);
    });

    test(
        'a server copy of a create still queued locally (its response was lost) '
        'is not shown twice', () async {
      final localId = await database.enqueueNote(
        userId: userId,
        title: 'Lost response',
        content: 'x',
        category: 'General',
        pinned: false,
        clientId: 'same-client-id',
        payload: '{}',
      );

      await database.replaceServerNotes(
        userId,
        [serverNote(9, 'Lost response', clientId: 'same-client-id')],
      );

      final notes = await database.getNotesForUser(userId);
      expect(notes.map((n) => n.id), [localId]);
    });

    test('rows of other users are left alone', () async {
      await database.replaceServerNotes(7, [
        NoteDatabaseMapper.fromNoteItem(7, NoteItem(noteId: 1, title: 'Theirs', content: '')),
      ]);
      await database.replaceServerNotes(userId, const []);
      expect(await database.getNotesForUser(7), hasLength(1));
    });
  });
}
