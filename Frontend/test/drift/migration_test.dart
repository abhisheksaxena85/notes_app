import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v2.dart' as v2;

/// Upgrades from every exported schema snapshot (drift_schemas/app_database)
/// to the current version and checks the result matches a fresh install.
///
/// After a schema change, regenerate the helpers in test/drift/generated:
///   dart run drift_dev schema generate drift_schemas/app_database/ \
///     test/drift/generated/ --data-classes --companions
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('every older schema upgrades to the current one', () {
    const current = 3;
    for (final from in GeneratedHelper.versions.where((v) => v < current)) {
      test('from v$from', () async {
        final schema = await verifier.schemaAt(from);
        final db = AppDatabase.forTesting(schema.newConnection());
        await verifier.migrateAndValidate(db, current);
        await db.close();
      });
    }
  });

  test('v2 → v3 keeps queued creates and gives each one a client id', () async {
    final schema = await verifier.schemaAt(2);
    final old = v2.DatabaseAtV2(schema.newConnection());
    final noteId = await old.into(old.cachedNotes).insert(
          v2.CachedNotesCompanion.insert(
            userId: 42,
            title: 'Queued before the update',
            content: 'body',
            isPending: const Value(1),
          ),
        );
    await old.into(old.pendingNotes).insert(
          v2.PendingNotesCompanion.insert(
            userId: 42,
            localNoteId: noteId,
            payload: jsonEncode({'userId': 42, 'title': 'Queued before the update'}),
          ),
        );
    final taskId = await old.into(old.cachedTasks).insert(
          v2.CachedTasksCompanion.insert(userId: 42, title: 'Old task'),
        );
    await old.into(old.pendingTasks).insert(
          v2.PendingTasksCompanion.insert(
            userId: 42,
            localTaskId: taskId,
            payload: jsonEncode({'userId': 42, 'title': 'Old task'}),
          ),
        );
    await old.into(old.cachedTasks).insert(
          v2.CachedTasksCompanion.insert(
            userId: 42,
            title: 'Already synced',
            serverId: const Value(7),
          ),
        );
    await old.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);

    final pendingNote = (await db.getPendingNotes(42)).single;
    expect(pendingNote.clientId, isNotNull);
    expect(pendingNote.attempts, 0);
    expect(pendingNote.failed, isFalse);
    expect(jsonDecode(pendingNote.payload), {
      'userId': 42,
      'title': 'Queued before the update',
      'clientId': pendingNote.clientId,
    });
    final cachedNote = (await db.getNotesForUser(42)).single;
    expect(cachedNote.clientId, pendingNote.clientId);

    final pendingTask = (await db.getPendingTasks(42)).single;
    expect(pendingTask.clientId, isNotNull);
    expect(pendingTask.clientId, isNot(pendingNote.clientId));
    final tasks = await db.getTasksForUser(42);
    expect(tasks.singleWhere((t) => t.id == taskId).clientId, pendingTask.clientId);
    expect(tasks.singleWhere((t) => t.serverId == 7).clientId, isNull,
        reason: 'synced rows had no queued create, so they get no client id');
    await db.close();
  });
}
