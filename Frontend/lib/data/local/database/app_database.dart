import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:notes_app/data/local/database/app_database.steps.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

class CachedNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get category => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get tags => text().nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isPending => boolean().withDefault(const Constant(false))();
  // FE-03: idempotency key sent with the create (see the backend client_id).
  TextColumn get clientId => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userId, serverId},
  ];
}

class PendingNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  IntColumn get localNoteId => integer()();
  TextColumn get payload => text()();
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();
  // FE-03: sync bookkeeping. `failed` marks a create the server refused for
  // good; automatic sync skips it until the user retries or discards it.
  TextColumn get clientId => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  BoolColumn get failed => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {localNoteId},
  ];
}

class CachedProfiles extends Table {
  IntColumn get userId => integer()();
  IntColumn get profileId => integer().nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get gender => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class CachedTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get dueDate => text().nullable()(); // YYYY-MM-DD
  TextColumn get dueTime => text().nullable()(); // HH:mm
  TextColumn get category => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('MEDIUM'))();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // PENDING, COMPLETED, REJECTED, MISSED
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  BoolColumn get isPending => boolean().withDefault(const Constant(false))();
  // FE-03: idempotency key sent with the create (see the backend client_id).
  TextColumn get clientId => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userId, serverId},
  ];
}

class PendingTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  IntColumn get localTaskId => integer()();
  TextColumn get payload => text()();
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();
  // FE-03: sync bookkeeping. `failed` marks a create the server refused for
  // good; automatic sync skips it until the user retries or discards it.
  TextColumn get clientId => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  BoolColumn get failed => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {localTaskId},
  ];
}

class CachedReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get remindAt => text()(); // ISO-8601
  TextColumn get dueDate => text().nullable()(); // YYYY-MM-DD
  TextColumn get dueTime => text().nullable()(); // HH:mm
  TextColumn get category => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // PENDING, COMPLETED, REJECTED, MISSED
  TextColumn get repeatInterval => text().withDefault(const Constant('NONE'))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  BoolColumn get isPending => boolean().withDefault(const Constant(false))();
  // FE-03: idempotency key sent with the create (see the backend client_id).
  TextColumn get clientId => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userId, serverId},
  ];
}

class PendingReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  IntColumn get localReminderId => integer()();
  TextColumn get payload => text()();
  DateTimeColumn get queuedAt => dateTime().withDefault(currentDateAndTime)();
  // FE-03: sync bookkeeping. `failed` marks a create the server refused for
  // good; automatic sync skips it until the user retries or discards it.
  TextColumn get clientId => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  BoolColumn get failed => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {localReminderId},
  ];
}

@DriftDatabase(tables: [
  CachedNotes,
  PendingNotes,
  CachedProfiles,
  CachedTasks,
  PendingTasks,
  CachedReminders,
  PendingReminders,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'notes_app'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  /// Each step uses the tables exactly as they were at that version (from the
  /// snapshots in `drift_schemas/`, generated into app_database.steps.dart), so
  /// later schema changes cannot break older steps. After changing a table:
  /// bump [schemaVersion], run `dart run drift_dev schema dump
  /// lib/data/local/database/app_database.dart drift_schemas/app_database/`,
  /// then `dart run drift_dev schema steps drift_schemas/app_database/
  /// lib/data/local/database/app_database.steps.dart`, add the new step here and
  /// regenerate the test helpers (see test/drift/migration_test.dart).
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.cachedTasks);
        await m.createTable(schema.pendingTasks);
        await m.createTable(schema.cachedReminders);
        await m.createTable(schema.pendingReminders);
      },
      from2To3: (m, schema) async {
        // FE-03: client ids for idempotent creates, and failure bookkeeping.
        await m.addColumn(schema.cachedNotes, schema.cachedNotes.clientId);
        await m.addColumn(schema.cachedTasks, schema.cachedTasks.clientId);
        await m.addColumn(schema.cachedReminders, schema.cachedReminders.clientId);
        for (final queue in [
          (schema.pendingNotes, schema.pendingNotes.clientId, schema.pendingNotes.attempts,
              schema.pendingNotes.lastError, schema.pendingNotes.failed),
          (schema.pendingTasks, schema.pendingTasks.clientId, schema.pendingTasks.attempts,
              schema.pendingTasks.lastError, schema.pendingTasks.failed),
          (schema.pendingReminders, schema.pendingReminders.clientId,
              schema.pendingReminders.attempts, schema.pendingReminders.lastError,
              schema.pendingReminders.failed),
        ]) {
          final (table, clientId, attempts, lastError, failed) = queue;
          await m.addColumn(table, clientId);
          await m.addColumn(table, attempts);
          await m.addColumn(table, lastError);
          await m.addColumn(table, failed);
        }
        await _backfillClientIds();
      },
    ),
  );

  /// v3: creates queued before the upgrade get a client id too, in the payload
  /// sent to the server and on both rows, so their retries are idempotent like
  /// new ones. Raw SQL on purpose: it must match the v3 tables, not whatever the
  /// table classes look like in a later version.
  Future<void> _backfillClientIds() async {
    const queues = [
      ('pending_notes', 'local_note_id', 'cached_notes'),
      ('pending_tasks', 'local_task_id', 'cached_tasks'),
      ('pending_reminders', 'local_reminder_id', 'cached_reminders'),
    ];
    for (final (queue, localColumn, cache) in queues) {
      final rows = await customSelect(
        'SELECT id, $localColumn AS local_id, payload FROM $queue',
      ).get();
      for (final row in rows) {
        final clientId = const Uuid().v4();
        var payload = row.read<String>('payload');
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            payload = jsonEncode({...decoded, 'clientId': clientId});
          }
        } on FormatException {
          // Left as is: the sync marks an unreadable payload as failed.
        }
        await customUpdate(
          'UPDATE $queue SET client_id = ?, payload = ? WHERE id = ?',
          variables: [
            Variable.withString(clientId),
            Variable.withString(payload),
            Variable.withInt(row.read<int>('id')),
          ],
        );
        await customUpdate(
          'UPDATE $cache SET client_id = ? WHERE id = ?',
          variables: [
            Variable.withString(clientId),
            Variable.withInt(row.read<int>('local_id')),
          ],
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Sync queue bookkeeping (FE-03)
  // ---------------------------------------------------------------------------

  static const _queueSql = {
    SyncEntity.note: ('pending_notes', 'local_note_id', 'cached_notes'),
    SyncEntity.task: ('pending_tasks', 'local_task_id', 'cached_tasks'),
    SyncEntity.reminder: ('pending_reminders', 'local_reminder_id', 'cached_reminders'),
  };

  TableInfo _queueTable(SyncEntity entity) => switch (entity) {
    SyncEntity.note => pendingNotes,
    SyncEntity.task => pendingTasks,
    SyncEntity.reminder => pendingReminders,
  };

  TableInfo _cacheTable(SyncEntity entity) => switch (entity) {
    SyncEntity.note => cachedNotes,
    SyncEntity.task => cachedTasks,
    SyncEntity.reminder => cachedReminders,
  };

  /// Counts a failed upload. [failed] marks it as refused for good, so the
  /// automatic sync skips it until [resetSyncFailure].
  Future<void> recordSyncAttempt(
    SyncEntity entity,
    int queueId, {
    required String error,
    required bool failed,
  }) async {
    final (queue, _, _) = _queueSql[entity]!;
    await customUpdate(
      'UPDATE $queue SET attempts = attempts + 1, last_error = ?, failed = ? WHERE id = ?',
      variables: [
        Variable.withString(error),
        Variable.withBool(failed),
        Variable.withInt(queueId),
      ],
      updates: {_queueTable(entity)},
    );
  }

  /// Puts a failed item back in line for the next sync.
  Future<void> resetSyncFailure(SyncEntity entity, int queueId) async {
    final (queue, _, _) = _queueSql[entity]!;
    await customUpdate(
      'UPDATE $queue SET attempts = 0, last_error = NULL, failed = 0 WHERE id = ?',
      variables: [Variable.withInt(queueId)],
      updates: {_queueTable(entity)},
    );
  }

  /// Drops a queued create the server refused, and the local-only row it
  /// would have created.
  Future<void> discardQueuedCreate(SyncEntity entity, int queueId) async {
    final (queue, localColumn, cache) = _queueSql[entity]!;
    await transaction(() async {
      await customUpdate(
        'DELETE FROM $cache WHERE server_id IS NULL AND id = '
        '(SELECT $localColumn FROM $queue WHERE id = ?)',
        variables: [Variable.withInt(queueId)],
        updates: {_cacheTable(entity)},
        updateKind: UpdateKind.delete,
      );
      await customUpdate(
        'DELETE FROM $queue WHERE id = ?',
        variables: [Variable.withInt(queueId)],
        updates: {_queueTable(entity)},
        updateKind: UpdateKind.delete,
      );
    });
  }

  /// Queued items the server refused for good, oldest first.
  Stream<List<SyncFailure>> watchSyncFailures(int userId) {
    final parts = <String>[];
    for (final entity in SyncEntity.values) {
      final (queue, localColumn, cache) = _queueSql[entity]!;
      parts.add(
        "SELECT '${entity.name}' AS entity, p.id AS queue_id, c.id AS local_id, "
        "COALESCE(c.title, '') AS title, p.last_error AS last_error, "
        'p.attempts AS attempts, p.queued_at AS queued_at '
        'FROM $queue p LEFT JOIN $cache c ON c.id = p.$localColumn '
        'WHERE p.user_id = ? AND p.failed = 1',
      );
    }
    return customSelect(
      '${parts.join(' UNION ALL ')} ORDER BY queued_at, queue_id',
      variables: [for (final _ in SyncEntity.values) Variable.withInt(userId)],
      readsFrom: {
        pendingNotes,
        pendingTasks,
        pendingReminders,
        cachedNotes,
        cachedTasks,
        cachedReminders,
      },
    ).watch().map(
      (rows) => [
        for (final row in rows)
          SyncFailure(
            entity: SyncEntity.values.byName(row.read<String>('entity')),
            queueId: row.read<int>('queue_id'),
            localId: row.readNullable<int>('local_id'),
            title: row.read<String>('title'),
            lastError: row.readNullable<String>('last_error'),
            attempts: row.read<int>('attempts'),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Notes Operations
  // ---------------------------------------------------------------------------

  Stream<List<CachedNote>> watchNotesForUser(int userId) {
    return (select(cachedNotes)
          ..where((note) => note.userId.equals(userId))
          ..orderBy([
            (note) =>
                OrderingTerm(expression: note.pinned, mode: OrderingMode.desc),
            (note) => OrderingTerm(
              expression: note.updatedAt,
              mode: OrderingMode.desc,
            ),
            (note) => OrderingTerm(
              expression: note.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<List<CachedNote>> getNotesForUser(int userId) {
    return (select(cachedNotes)
          ..where((note) => note.userId.equals(userId))
          ..orderBy([
            (note) =>
                OrderingTerm(expression: note.pinned, mode: OrderingMode.desc),
            (note) => OrderingTerm(
              expression: note.updatedAt,
              mode: OrderingMode.desc,
            ),
            (note) => OrderingTerm(
              expression: note.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<CachedNote?> getNote(int userId, int noteId) {
    final query = select(cachedNotes)
      ..where(
        (note) =>
            note.userId.equals(userId) &
            (noteId < 0
                ? note.id.equals(-noteId)
                : note.serverId.equals(noteId)),
      );
    return query.getSingleOrNull();
  }

  /// Merges a fresh server list into the cache; see [_mergeServerRows].
  Future<void> replaceServerNotes(
    int userId,
    List<CachedNotesCompanion> notes,
  ) => _mergeServerRows(_notesRows, userId, notes);

  Future<int> enqueueNote({
    required int userId,
    required String title,
    required String content,
    required String category,
    required bool pinned,
    String? tags,
    String? createdAt,
    String? updatedAt,
    required String clientId,
    required String payload,
  }) async {
    final now = DateTime.now().toIso8601String();
    return transaction(() async {
      final localNoteId = await into(cachedNotes).insert(
        CachedNotesCompanion.insert(
          userId: userId,
          title: title,
          content: content,
          category: Value(category),
          createdAt: Value(createdAt ?? now),
          updatedAt: Value(updatedAt ?? now),
          pinned: Value(pinned),
          tags: Value(tags),
          isPending: const Value(true),
          clientId: Value(clientId),
        ),
      );
      await into(pendingNotes).insert(
        PendingNotesCompanion.insert(
          userId: userId,
          localNoteId: localNoteId,
          payload: payload,
          clientId: Value(clientId),
        ),
      );
      return localNoteId;
    });
  }

  Future<CachedNote?> findDuplicateNote({
    required int userId,
    required String title,
    required String content,
  }) {
    return (select(cachedNotes)
          ..where((note) =>
              note.userId.equals(userId) &
              note.title.equals(title) &
              note.content.equals(content))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<CachedNote?> getNoteByServerId(int userId, int serverId) {
    return (select(cachedNotes)
          ..where((note) =>
              note.userId.equals(userId) & note.serverId.equals(serverId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> updateCachedNote(CachedNotesCompanion note) async {
    await (update(cachedNotes)..where((n) => n.id.equals(note.id.value))).write(note);
  }

  Future<List<PendingNote>> getPendingNotes(int userId) {
    return (select(pendingNotes)
          ..where((pending) => pending.userId.equals(userId))
          ..orderBy([(pending) => OrderingTerm.asc(pending.id)]))
        .get();
  }

  Future<void> completePendingNote({
    required int queueId,
    required int localNoteId,
    required int serverId,
  }) async {
    await transaction(() async {
      // If a refresh already cached the server copy (the create succeeded but
      // its response was lost), drop that copy so the local row keeps its id.
      final local = await (select(cachedNotes)
            ..where((note) => note.id.equals(localNoteId)))
          .getSingleOrNull();
      if (local != null) {
        await (delete(cachedNotes)..where((note) =>
              note.userId.equals(local.userId) &
              note.serverId.equals(serverId) &
              note.id.equals(localNoteId).not()))
            .go();
      }
      await (update(
        cachedNotes,
      )..where((note) => note.id.equals(localNoteId))).write(
        CachedNotesCompanion(
          serverId: Value(serverId),
          isPending: const Value(false),
        ),
      );
      await (delete(
        pendingNotes,
      )..where((entry) => entry.id.equals(queueId))).go();
    });
  }

  Future<void> saveServerNote(CachedNotesCompanion note) =>
      _upsertByServerId(_notesRows, note);

  // ---------------------------------------------------------------------------
  // Server rows: upsert and merge (FE-04)
  // ---------------------------------------------------------------------------

  late final _notesRows = _ServerRows<$CachedNotesTable, CachedNote, CachedNotesCompanion>(
    table: cachedNotes,
    id: (t) => t.id,
    userId: (t) => t.userId,
    serverId: (t) => t.serverId,
    clientId: (t) => t.clientId,
    isPending: (t) => t.isPending,
    companionUserId: (c) => c.userId,
    companionServerId: (c) => c.serverId,
    companionClientId: (c) => c.clientId,
  );

  late final _tasksRows = _ServerRows<$CachedTasksTable, CachedTask, CachedTasksCompanion>(
    table: cachedTasks,
    id: (t) => t.id,
    userId: (t) => t.userId,
    serverId: (t) => t.serverId,
    clientId: (t) => t.clientId,
    isPending: (t) => t.isPending,
    companionUserId: (c) => c.userId,
    companionServerId: (c) => c.serverId,
    companionClientId: (c) => c.clientId,
  );

  late final _remindersRows =
      _ServerRows<$CachedRemindersTable, CachedReminder, CachedRemindersCompanion>(
    table: cachedReminders,
    id: (t) => t.id,
    userId: (t) => t.userId,
    serverId: (t) => t.serverId,
    clientId: (t) => t.clientId,
    isPending: (t) => t.isPending,
    companionUserId: (c) => c.userId,
    companionServerId: (c) => c.serverId,
    companionClientId: (c) => c.clientId,
  );

  /// Writes a server copy over the cached row with the same (userId, serverId)
  /// and keeps that row's local id; inserts it if it is not cached yet.
  /// (`insertOnConflictUpdate` only targets the primary key, which server
  /// copies don't carry, so it broke the unique (userId, serverId) key.)
  /// Returns the local id.
  Future<int> _upsertByServerId<T extends Table, D, C extends UpdateCompanion<D>>(
    _ServerRows<T, D, C> rows,
    C row,
  ) {
    return transaction(() async {
      final serverId = rows.companionServerId(row);
      if (!serverId.present || serverId.value == null) {
        return into(rows.table).insert(row);
      }
      final t = rows.table.asDslTable;
      final match = rows.userId(t).equals(rows.companionUserId(row).value) &
          rows.serverId(t).equals(serverId.value!);
      final existing = await (selectOnly(rows.table)
            ..addColumns([rows.id(t)])
            ..where(match))
          .map((r) => r.read(rows.id(t))!)
          .getSingleOrNull();
      if (existing == null) return into(rows.table).insert(row);
      await (update(rows.table)..where((_) => match)).write(row);
      return existing;
    });
  }

  /// A refresh from the server, as a merge in one transaction:
  /// - each server item is upserted by (userId, serverId), keeping its local
  ///   id (stable ids, no delete-and-reinsert flicker);
  /// - rows with local changes not yet on the server (`isPending`) win: they
  ///   are neither overwritten nor deleted until the queue has replayed them;
  /// - a server item whose clientId matches a create still queued here (its
  ///   response was lost) is skipped; the retried create links the two;
  /// - synced rows missing from the server list are deleted;
  /// - local-only rows (no serverId) are never touched.
  Future<void> _mergeServerRows<T extends Table, D, C extends UpdateCompanion<D>>(
    _ServerRows<T, D, C> rows,
    int userId,
    List<C> serverRows,
  ) {
    return transaction(() async {
      final t = rows.table.asDslTable;
      final pending = await (selectOnly(rows.table)
            ..addColumns([rows.serverId(t), rows.clientId(t)])
            ..where(rows.userId(t).equals(userId) & rows.isPending(t).equals(true)))
          .get();
      final pendingServerIds = {
        for (final r in pending) ?r.read(rows.serverId(t)),
      };
      final pendingClientIds = {
        for (final r in pending) ?r.read(rows.clientId(t)),
      };

      final listedServerIds = <int>{};
      for (final row in serverRows) {
        final serverId = rows.companionServerId(row);
        if (!serverId.present || serverId.value == null) continue;
        listedServerIds.add(serverId.value!);
        if (pendingServerIds.contains(serverId.value)) continue;
        final clientId = rows.companionClientId(row);
        if (clientId.present && pendingClientIds.contains(clientId.value)) continue;
        await _upsertByServerId(rows, row);
      }

      await (delete(rows.table)
            ..where((_) =>
                rows.userId(t).equals(userId) &
                rows.serverId(t).isNotNull() &
                rows.serverId(t).isNotIn(listedServerIds) &
                rows.isPending(t).equals(false)))
          .go();
    });
  }

  // ---------------------------------------------------------------------------
  // Profile Operations
  // ---------------------------------------------------------------------------

  Stream<CachedProfile?> watchProfile(int userId) {
    return (select(
      cachedProfiles,
    )..where((profile) => profile.userId.equals(userId))).watchSingleOrNull();
  }

  Future<CachedProfile?> getProfile(int userId) {
    return (select(
      cachedProfiles,
    )..where((profile) => profile.userId.equals(userId))).getSingleOrNull();
  }

  Future<void> saveProfile(CachedProfilesCompanion profile) async {
    await into(cachedProfiles).insertOnConflictUpdate(profile);
  }

  // ---------------------------------------------------------------------------
  // Task Operations
  // ---------------------------------------------------------------------------

  Stream<List<CachedTask>> watchTasksForUser(int userId) {
    return (select(cachedTasks)
          ..where((task) => task.userId.equals(userId))
          ..orderBy([
            (task) => OrderingTerm(expression: task.isCompleted, mode: OrderingMode.asc),
            (task) => OrderingTerm(expression: task.dueDate, mode: OrderingMode.asc),
            (task) => OrderingTerm(expression: task.dueTime, mode: OrderingMode.asc),
            (task) => OrderingTerm(expression: task.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<CachedTask>> getTasksForUser(int userId) {
    return (select(cachedTasks)
          ..where((task) => task.userId.equals(userId))
          ..orderBy([
            (task) => OrderingTerm(expression: task.isCompleted, mode: OrderingMode.asc),
            (task) => OrderingTerm(expression: task.dueDate, mode: OrderingMode.asc),
            (task) => OrderingTerm(expression: task.dueTime, mode: OrderingMode.asc),
            (task) => OrderingTerm(expression: task.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<List<CachedTask>> getTasksByDate(int userId, String date) {
    return (select(cachedTasks)
          ..where((task) =>
              task.userId.equals(userId) &
              (task.dueDate.equals(date) |
                  (task.dueDate.isNull() & task.createdAt.like('$date%'))))
          ..orderBy([
            (task) => OrderingTerm(expression: task.isCompleted, mode: OrderingMode.asc),
            (task) => OrderingTerm(expression: task.dueTime, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<int> enqueueTask({
    required int userId,
    required String title,
    String? description,
    String? dueDate,
    String? dueTime,
    String? category,
    String? priority,
    String? status,
    bool isCompleted = false,
    required String clientId,
    required String payload,
  }) async {
    final now = DateTime.now().toIso8601String();
    return transaction(() async {
      final localTaskId = await into(cachedTasks).insert(
        CachedTasksCompanion.insert(
          userId: userId,
          title: title,
          description: Value(description),
          dueDate: Value(dueDate),
          dueTime: Value(dueTime),
          category: Value(category ?? 'General'),
          priority: Value(priority ?? 'MEDIUM'),
          status: Value(status ?? (isCompleted ? 'COMPLETED' : 'PENDING')),
          isCompleted: Value(isCompleted),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPending: const Value(true),
          clientId: Value(clientId),
        ),
      );
      await into(pendingTasks).insert(
        PendingTasksCompanion.insert(
          userId: userId,
          localTaskId: localTaskId,
          payload: payload,
          clientId: Value(clientId),
        ),
      );
      return localTaskId;
    });
  }

  Future<List<PendingTask>> getPendingTasks(int userId) {
    return (select(pendingTasks)
          ..where((pending) => pending.userId.equals(userId))
          ..orderBy([(pending) => OrderingTerm.asc(pending.id)]))
        .get();
  }

  Future<void> completePendingTask({
    required int queueId,
    required int localTaskId,
    required int serverId,
  }) async {
    await transaction(() async {
      // See completePendingNote.
      final local = await (select(cachedTasks)
            ..where((task) => task.id.equals(localTaskId)))
          .getSingleOrNull();
      if (local != null) {
        await (delete(cachedTasks)..where((task) =>
              task.userId.equals(local.userId) &
              task.serverId.equals(serverId) &
              task.id.equals(localTaskId).not()))
            .go();
      }
      await (update(cachedTasks)..where((task) => task.id.equals(localTaskId))).write(
        CachedTasksCompanion(
          serverId: Value(serverId),
          isPending: const Value(false),
        ),
      );
      await (delete(pendingTasks)..where((entry) => entry.id.equals(queueId))).go();
    });
  }

  /// Merges a fresh server list into the cache; see [_mergeServerRows].
  Future<void> replaceServerTasks(
    int userId,
    List<CachedTasksCompanion> tasks,
  ) => _mergeServerRows(_tasksRows, userId, tasks);

  Future<void> saveServerTask(CachedTasksCompanion task) =>
      _upsertByServerId(_tasksRows, task);

  Future<PendingTask?> getPendingTaskForLocalId(int localTaskId) {
    return (select(pendingTasks)
          ..where((entry) => entry.localTaskId.equals(localTaskId)))
        .getSingleOrNull();
  }

  Future<void> updatePendingTaskPayload(int queueId, String payload) async {
    await (update(pendingTasks)..where((entry) => entry.id.equals(queueId)))
        .write(PendingTasksCompanion(payload: Value(payload)));
  }

  Future<void> updateTaskStatus({
    required int taskId,
    required String status,
    required bool isCompleted,
  }) async {
    final now = DateTime.now().toIso8601String();
    await (update(cachedTasks)
          ..where((task) =>
              (taskId < 0 ? task.id.equals(-taskId) : task.serverId.equals(taskId))))
        .write(
      CachedTasksCompanion(
        status: Value(status),
        isCompleted: Value(isCompleted),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteCachedTask(int taskId) async {
    await transaction(() async {
      await (delete(cachedTasks)
            ..where((task) =>
                (taskId < 0 ? task.id.equals(-taskId) : task.serverId.equals(taskId))))
          .go();
      // A negative id is a never-synced local row: drop its queued upload too,
      // otherwise the next sync would recreate it on the server.
      if (taskId < 0) {
        await (delete(pendingTasks)
              ..where((entry) => entry.localTaskId.equals(-taskId)))
            .go();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Reminder Operations
  // ---------------------------------------------------------------------------

  Stream<List<CachedReminder>> watchRemindersForUser(int userId) {
    return (select(cachedReminders)
          ..where((rem) => rem.userId.equals(userId))
          ..orderBy([
            (rem) => OrderingTerm(expression: rem.remindAt, mode: OrderingMode.asc),
            (rem) => OrderingTerm(expression: rem.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<CachedReminder>> getRemindersForUser(int userId) {
    return (select(cachedReminders)
          ..where((rem) => rem.userId.equals(userId))
          ..orderBy([
            (rem) => OrderingTerm(expression: rem.remindAt, mode: OrderingMode.asc),
            (rem) => OrderingTerm(expression: rem.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<List<CachedReminder>> getRemindersByDate(int userId, String date) {
    return (select(cachedReminders)
          ..where((rem) =>
              rem.userId.equals(userId) &
              (rem.dueDate.equals(date) |
                  (rem.dueDate.isNull() & rem.remindAt.like('$date%'))))
          ..orderBy([
            (rem) => OrderingTerm(expression: rem.dueTime, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<int> enqueueReminder({
    required int userId,
    required String title,
    required String remindAt,
    String? dueDate,
    String? dueTime,
    String? category,
    String? status,
    String? repeatInterval,
    required String clientId,
    required String payload,
  }) async {
    final now = DateTime.now().toIso8601String();
    return transaction(() async {
      final localReminderId = await into(cachedReminders).insert(
        CachedRemindersCompanion.insert(
          userId: userId,
          title: title,
          remindAt: remindAt,
          dueDate: Value(dueDate),
          dueTime: Value(dueTime),
          category: Value(category ?? 'General'),
          status: Value(status ?? 'PENDING'),
          repeatInterval: Value(repeatInterval ?? 'NONE'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPending: const Value(true),
          clientId: Value(clientId),
        ),
      );
      await into(pendingReminders).insert(
        PendingRemindersCompanion.insert(
          userId: userId,
          localReminderId: localReminderId,
          payload: payload,
          clientId: Value(clientId),
        ),
      );
      return localReminderId;
    });
  }

  Future<List<PendingReminder>> getPendingReminders(int userId) {
    return (select(pendingReminders)
          ..where((pending) => pending.userId.equals(userId))
          ..orderBy([(pending) => OrderingTerm.asc(pending.id)]))
        .get();
  }

  Future<void> completePendingReminder({
    required int queueId,
    required int localReminderId,
    required int serverId,
  }) async {
    await transaction(() async {
      // See completePendingNote.
      final local = await (select(cachedReminders)
            ..where((rem) => rem.id.equals(localReminderId)))
          .getSingleOrNull();
      if (local != null) {
        await (delete(cachedReminders)..where((rem) =>
              rem.userId.equals(local.userId) &
              rem.serverId.equals(serverId) &
              rem.id.equals(localReminderId).not()))
            .go();
      }
      await (update(cachedReminders)..where((rem) => rem.id.equals(localReminderId))).write(
        CachedRemindersCompanion(
          serverId: Value(serverId),
          isPending: const Value(false),
        ),
      );
      await (delete(pendingReminders)..where((entry) => entry.id.equals(queueId))).go();
    });
  }

  /// Merges a fresh server list into the cache; see [_mergeServerRows].
  Future<void> replaceServerReminders(
    int userId,
    List<CachedRemindersCompanion> reminders,
  ) => _mergeServerRows(_remindersRows, userId, reminders);

  Future<void> saveServerReminder(CachedRemindersCompanion reminder) =>
      _upsertByServerId(_remindersRows, reminder);

  Future<PendingReminder?> getPendingReminderForLocalId(int localReminderId) {
    return (select(pendingReminders)
          ..where((entry) => entry.localReminderId.equals(localReminderId)))
        .getSingleOrNull();
  }

  Future<void> updatePendingReminderPayload(int queueId, String payload) async {
    await (update(pendingReminders)..where((entry) => entry.id.equals(queueId)))
        .write(PendingRemindersCompanion(payload: Value(payload)));
  }

  Future<void> updateReminderStatus({
    required int reminderId,
    required String status,
  }) async {
    final now = DateTime.now().toIso8601String();
    await (update(cachedReminders)
          ..where((rem) =>
              (reminderId < 0 ? rem.id.equals(-reminderId) : rem.serverId.equals(reminderId))))
        .write(
      CachedRemindersCompanion(
        status: Value(status),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteCachedReminder(int reminderId) async {
    await transaction(() async {
      await (delete(cachedReminders)
            ..where((rem) =>
                (reminderId < 0 ? rem.id.equals(-reminderId) : rem.serverId.equals(reminderId))))
          .go();
      // See deleteCachedTask: never-synced rows must leave the upload queue too.
      if (reminderId < 0) {
        await (delete(pendingReminders)
              ..where((entry) => entry.localReminderId.equals(-reminderId)))
            .go();
      }
    });
  }
}

/// Column accessors for the three cached tables that mirror server rows
/// (notes, tasks, reminders), so upsert and merge are written once.
class _ServerRows<T extends Table, D, C extends UpdateCompanion<D>> {
  final TableInfo<T, D> table;
  final GeneratedColumn<int> Function(T) id;
  final GeneratedColumn<int> Function(T) userId;
  final GeneratedColumn<int> Function(T) serverId;
  final GeneratedColumn<String> Function(T) clientId;
  final GeneratedColumn<bool> Function(T) isPending;
  final Value<int> Function(C) companionUserId;
  final Value<int?> Function(C) companionServerId;
  final Value<String?> Function(C) companionClientId;

  const _ServerRows({
    required this.table,
    required this.id,
    required this.userId,
    required this.serverId,
    required this.clientId,
    required this.isPending,
    required this.companionUserId,
    required this.companionServerId,
    required this.companionClientId,
  });
}
