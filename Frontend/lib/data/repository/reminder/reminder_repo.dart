import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:notes_app/data/local/database/reminder_database_mapper.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/date/date_keys.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:uuid/uuid.dart';

class ReminderRepo {
  final ApiClient client;
  final AppDatabase database;
  final OfflineSyncService syncService;

  ReminderRepo({
    required this.client,
    required this.database,
    required this.syncService,
  });

  Future<List<ReminderItem>> getCachedReminders(int userId) async {
    final cached = await database.getRemindersForUser(userId);
    return cached.map(ReminderDatabaseMapper.toReminderItem).toList();
  }

  Stream<List<ReminderItem>> watchReminders(int userId) {
    return database
        .watchRemindersForUser(userId)
        .map((reminders) => reminders.map(ReminderDatabaseMapper.toReminderItem).toList());
  }

  /// Refreshes the cache from the server. Runs while no sync pass is
  /// running, so the merge can't undo a change that was just replayed.
  Future<List<ReminderItem>> fetchAndCacheReminders(int userId) {
    return syncService.runExclusive(() => _fetchAndMerge(userId));
  }

  Future<List<ReminderItem>> _fetchAndMerge(int userId) async {
    try {
      final response = await client.getAllReminders(userId);
      if (response.statusCode != 200) {
        return await getCachedReminders(userId);
      }

      final body = response.data;
      List<dynamic> items = [];
      if (body is Map && body['data'] is List) {
        items = body['data'] as List;
      } else if (body is List) {
        items = body;
      }

      final reminderItems = items
          .map((item) => ReminderItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      final companions = reminderItems
          .map((r) => ReminderDatabaseMapper.fromReminderItem(userId, r))
          .toList();

      await database.replaceServerReminders(userId, companions);
      return reminderItems;
    } catch (e) {
      return getCachedReminders(userId);
    }
  }

  /// Saves the reminder locally, queues its upload (tagged with a new client id
  /// so a retried upload can't create it twice) and asks for a sync.
  Future<int> enqueueReminder(CreateReminderRequestDto requestDto) async {
    final userId = requestDto.userId;
    final title = requestDto.title;
    if (title.trim().isEmpty) {
      throw ArgumentError('A reminder requires a title.');
    }

    final clientId = const Uuid().v4();
    final startAt = requestDto.startAt ?? requestDto.remindAt;
    final localId = await database.enqueueReminder(
      userId: userId,
      title: title,
      remindAt: requestDto.remindAt,
      dueDate: requestDto.dueDate,
      dueTime: requestDto.dueTime,
      category: requestDto.category ?? 'General',
      status: requestDto.status ?? 'PENDING',
      repeatInterval: requestDto.repeatInterval ?? 'NONE',
      startAt: startAt,
      clientId: clientId,
      payload: jsonEncode({...requestDto.toJson(), 'startAt': startAt, 'clientId': clientId}),
    );
    unawaited(syncService.requestSync());
    return localId;
  }

  /// Sets the status locally and queues it (FE-02). For a reminder that was
  /// never uploaded the queued create carries the new status instead.
  Future<void> updateReminderStatus(int userId, int reminderId, String status) async {
    await database.recordItemChange(
      entity: SyncEntity.reminder,
      userId: userId,
      itemId: reminderId,
      op: 'status',
      changes: {'status': status},
      applyToRow: (localId) => _writeRow(
        localId,
        // An answered reminder is no longer snoozed.
        CachedRemindersCompanion(status: Value(status), snoozedUntil: const Value(null)),
      ),
    );
    unawaited(syncService.requestSync());
  }

  /// Saves an edit locally and queues it (FE-02); works for unsynced
  /// reminders and offline. Throws [StateError] if it doesn't exist.
  ///
  /// A new `remindAt` also moves `dueDate`/`dueTime` (unless given), clears a
  /// snooze, and re-anchors a repeating series there unless `startAt` is
  /// given, the same rules as the server (REM-07). The scheduler then
  /// reschedules the notification (REM-03).
  Future<void> updateReminder(int userId, UpdateReminderRequestDto requestDto) async {
    final changes = requestDto.toJson()..remove('reminderId');
    var dto = requestDto;
    final remindAt = requestDto.remindAt;
    if (remindAt != null) {
      final at = parseWallClock(remindAt);
      if (at == null) throw ArgumentError.value(remindAt, 'remindAt', 'is not a date and time');
      final normalized = formatWallClock(at);
      dto = UpdateReminderRequestDto(
        reminderId: requestDto.reminderId,
        title: requestDto.title,
        remindAt: normalized,
        dueDate: requestDto.dueDate ?? formatDueDate(at),
        dueTime: requestDto.dueTime ?? formatDueTime(at),
        category: requestDto.category,
        status: requestDto.status,
        repeatInterval: requestDto.repeatInterval,
        startAt: requestDto.startAt ?? normalized,
        lastOutcome: requestDto.lastOutcome,
        lastOutcomeAt: requestDto.lastOutcomeAt,
      );
      changes
        ..clear()
        ..addAll(dto.toJson()..remove('reminderId'));
    }
    await database.recordItemChange(
      entity: SyncEntity.reminder,
      userId: userId,
      itemId: requestDto.reminderId,
      op: 'update',
      changes: changes,
      applyToRow: (localId) => _writeRow(
        localId,
        CachedRemindersCompanion(
          title: _set(dto.title),
          remindAt: _set(dto.remindAt),
          dueDate: _set(dto.dueDate),
          dueTime: _set(dto.dueTime),
          category: _set(dto.category),
          status: _set(dto.status),
          repeatInterval: _set(dto.repeatInterval),
          startAt: _set(dto.startAt),
          lastOutcome: _set(dto.lastOutcome),
          lastOutcomeAt: _set(dto.lastOutcomeAt),
          snoozedUntil: remindAt != null ? const Value(null) : const Value.absent(),
        ),
      ),
    );
    unawaited(syncService.requestSync());
  }

  /// REM-05 catch-up: a repeating reminder whose occurrence passed without an
  /// answer (the app was closed) moves to [next], keeping its anchor, and
  /// records the missed occurrence. Queued like any edit.
  Future<void> advanceMissedOccurrence(int userId, CachedReminder row, DateTime next) {
    return updateReminder(
      userId,
      UpdateReminderRequestDto(
        reminderId: itemIdOf(row),
        remindAt: formatWallClock(next),
        startAt: row.startAt ?? row.remindAt,
        lastOutcome: 'MISSED',
        lastOutcomeAt: row.remindAt,
      ),
    );
  }

  /// REM-04 "Snooze": the notification comes back at [until]. Local only:
  /// nothing is queued for the server and the status doesn't change.
  Future<void> snoozeReminder(int userId, int localId, DateTime until) async {
    await (database.update(database.cachedReminders)
          ..where((r) => r.id.equals(localId) & r.userId.equals(userId)))
        .write(CachedRemindersCompanion(snoozedUntil: Value(until.toUtc().toIso8601String())));
  }

  /// The id the UI and the outbox use for a cached row: the server id, or the
  /// negative local id before the first sync.
  static int itemIdOf(CachedReminder row) => row.serverId ?? -row.id;

  /// Deletes locally and queues the delete (FE-02); see TaskRepo.deleteTask.
  Future<void> deleteReminder(int userId, int reminderId) async {
    final deleted = await database.recordItemDelete(
      entity: SyncEntity.reminder,
      userId: userId,
      itemId: reminderId,
    );
    if (deleted) unawaited(syncService.requestSync());
  }

  Future<void> _writeRow(int localId, CachedRemindersCompanion changes) async {
    await (database.update(database.cachedReminders)..where((r) => r.id.equals(localId)))
        .write(changes.copyWith(updatedAt: Value(DateKeys.nowUtc())));
  }

  static Value<T> _set<T>(T? value) => value == null ? const Value.absent() : Value(value);

  Future<List<ReminderItem>> getRemindersByDate(int userId, String date) async {
    final cached = await database.getRemindersByDate(userId, date);
    return cached.map(ReminderDatabaseMapper.toReminderItem).toList();
  }
}
