import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/note_database_mapper.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'remote refresh preserves queued notes and sync removes only queue row',
    () async {
      final localId = await database.enqueueNote(
        userId: 42,
        title: 'Offline note',
        content: 'Saved before upload',
        category: 'General',
        pinned: false,
        clientId: 'client-1',
        payload: '{"userId":42,"title":"Offline note","clientId":"client-1"}',
      );
      await database.replaceServerNotes(42, [
        NoteDatabaseMapper.fromNoteItem(
          42,
          NoteItem(noteId: 8, title: 'Old note', content: 'Stale snapshot'),
        ),
      ]);
      await database.replaceServerNotes(42, [
        NoteDatabaseMapper.fromNoteItem(
          42,
          NoteItem(noteId: 9, title: 'Cached note', content: 'From server'),
        ),
      ]);

      final notesBeforeSync = await database.getNotesForUser(42);
      final queue = await database.getPendingNotes(42);
      expect(notesBeforeSync, hasLength(2));
      expect(queue, hasLength(1));
      expect(
        notesBeforeSync
            .map(NoteDatabaseMapper.toNoteItem)
            .map((note) => note.noteId),
        contains(-localId),
      );
      expect(
        notesBeforeSync.map(NoteDatabaseMapper.toNoteItem).map((note) => note.noteId),
        isNot(contains(8)),
      );

      await database.completePendingNote(
        queueId: queue.single.id,
        localNoteId: localId,
        serverId: 10,
      );

      expect(await database.getPendingNotes(42), isEmpty);
      final notesAfterSync = (await database.getNotesForUser(42))
          .map(NoteDatabaseMapper.toNoteItem);
      expect(notesAfterSync.map((note) => note.noteId), contains(10));
      expect(notesAfterSync.map((note) => note.noteId), contains(9));
    },
  );

  test('profile data is stored per user', () async {
    await database.saveProfile(
      CachedProfilesCompanion.insert(
        userId: const Value(42),
        profileId: const Value(7),
        name: const Value('Offline User'),
        email: const Value('offline@example.com'),
        mobile: const Value('1234567890'),
        gender: const Value('other'),
      ),
    );

    final profile = await database.getProfile(42);
    expect(profile?.profileId, 7);
    expect(profile?.name, 'Offline User');
    expect(await database.getProfile(24), isNull);
  });
}
