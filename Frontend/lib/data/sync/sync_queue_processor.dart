import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/sync/sync_error.dart';

/// Uploads the offline queues. Only [OfflineSyncService] uses this, so every
/// upload goes through its single-flight `requestSync()`.
///
/// Each `upload*` method processes one entity's queue in order and returns
/// true if it stopped on a transient error (so the caller can back off).
/// Items the server refuses for good are marked failed and skipped, so one bad
/// item never blocks the ones after it.
class SyncQueueProcessor {
  final ApiClient client;
  final AppDatabase database;

  SyncQueueProcessor({required this.client, required this.database});

  Future<bool> uploadNotes(int userId) async {
    final queue = await database.getPendingNotes(userId);
    return _drain(
      SyncEntity.note,
      [for (final item in queue) if (!item.failed) (item.id, () => _uploadNote(item))],
    );
  }

  Future<bool> uploadTasks(int userId) async {
    final queue = await database.getPendingTasks(userId);
    return _drain(
      SyncEntity.task,
      [for (final item in queue) if (!item.failed) (item.id, () => _uploadTask(item))],
    );
  }

  Future<bool> uploadReminders(int userId) async {
    final queue = await database.getPendingReminders(userId);
    return _drain(
      SyncEntity.reminder,
      [for (final item in queue) if (!item.failed) (item.id, () => _uploadReminder(item))],
    );
  }

  Future<bool> _drain(
    SyncEntity entity,
    List<(int, Future<void> Function())> uploads,
  ) async {
    for (final (queueId, upload) in uploads) {
      try {
        await upload();
      } catch (error) {
        final kind = classifySyncError(error);
        final message = describeSyncError(error);
        await database.recordSyncAttempt(
          entity,
          queueId,
          error: message,
          failed: kind == SyncErrorKind.permanent,
        );
        if (kind == SyncErrorKind.transient) {
          log('Sync of ${entity.name} $queueId paused: $message');
          return true;
        }
        log('Sync of ${entity.name} $queueId refused: $message');
      }
    }
    return false;
  }

  /// The queued payload, with the row's client id added for payloads written
  /// before client ids existed.
  Map<String, dynamic> _payload(String raw, String? clientId) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Queued payload must be an object.');
    }
    final payload = Map<String, dynamic>.from(decoded);
    if (clientId != null) payload['clientId'] ??= clientId;
    return payload;
  }

  Future<void> _uploadNote(PendingNote item) async {
    final request = CreateNoteRequestDto.fromJson(_payload(item.payload, item.clientId));
    final response = await client.createNote(request);
    final serverId = _createdId(response, const ['noteId', 'id']);
    await database.completePendingNote(
      queueId: item.id,
      localNoteId: item.localNoteId,
      serverId: serverId,
    );
  }

  Future<void> _uploadTask(PendingTask item) async {
    final request = CreateTaskRequestDto.fromJson(_payload(item.payload, item.clientId));
    final response = await client.createTask(request);
    final serverId = _createdId(response, const ['taskId', 'id']);
    await database.completePendingTask(
      queueId: item.id,
      localTaskId: item.localTaskId,
      serverId: serverId,
    );
  }

  Future<void> _uploadReminder(PendingReminder item) async {
    final request = CreateReminderRequestDto.fromJson(
      _payload(item.payload, item.clientId),
    );
    final response = await client.createReminder(request);
    final serverId = _createdId(response, const ['reminderId', 'id']);
    await database.completePendingReminder(
      queueId: item.id,
      localReminderId: item.localReminderId,
      serverId: serverId,
    );
  }

  /// The new server id from an `ApiResponse` body, or a [SyncRejectedException]
  /// when the server answered 2xx without creating anything.
  int _createdId(Response response, List<String> keys) {
    ensureSuccessStatus(response);
    final body = response.data;
    if (body is! Map || body['success'] != true) {
      final message = body is Map && body['message'] is String
          ? body['message'] as String
          : 'The server did not accept the item.';
      throw SyncRejectedException(message);
    }
    final data = body['data'];
    if (data is Map) {
      for (final key in keys) {
        final raw = data[key];
        if (raw is int) return raw;
        if (raw is String && int.tryParse(raw) != null) return int.parse(raw);
      }
    }
    throw const SyncRejectedException('The server did not return an id.');
  }
}
