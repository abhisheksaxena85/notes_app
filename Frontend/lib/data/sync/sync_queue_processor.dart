import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/note/update_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/update_task_request_dto.dart';
import 'package:notes_app/data/sync/sync_error.dart';

/// Uploads the offline queues. Only [OfflineSyncService] uses this, so every
/// upload goes through its single-flight `requestSync()`.
///
/// For each entity, [uploadCreates] sends queued creates and then
/// [replayMutations] sends queued updates, status changes and deletes. Both
/// return true if they stopped on a transient error (so the caller can back
/// off). Items the server refuses for good are marked failed and skipped, so
/// one bad item never blocks the others.
class SyncQueueProcessor {
  final ApiClient client;
  final AppDatabase database;

  SyncQueueProcessor({required this.client, required this.database});

  Future<bool> uploadCreates(SyncEntity entity, int userId) async {
    final uploads = <(int, Future<void> Function())>[];
    switch (entity) {
      case SyncEntity.note:
        for (final item in await database.getPendingNotes(userId)) {
          if (!item.failed) uploads.add((item.id, () => _uploadNote(item)));
        }
      case SyncEntity.task:
        for (final item in await database.getPendingTasks(userId)) {
          if (!item.failed) uploads.add((item.id, () => _uploadTask(item)));
        }
      case SyncEntity.reminder:
        for (final item in await database.getPendingReminders(userId)) {
          if (!item.failed) uploads.add((item.id, () => _uploadReminder(item)));
        }
    }

    for (final (queueId, upload) in uploads) {
      try {
        await upload();
      } catch (error) {
        final transient = await _recordFailure(
          '${entity.name} create $queueId',
          error,
          (message, failed) =>
              database.recordSyncAttempt(entity, queueId, error: message, failed: failed),
        );
        if (transient) return true;
      }
    }
    return false;
  }

  /// Sends queued update/status/delete changes in the order they were made.
  ///
  /// A change for an item whose create hasn't completed yet waits (its server
  /// id is not known), and so do later changes to the same item, which keeps
  /// each item's changes in order. A 404 means the server no longer has the
  /// item, so the change is dropped.
  Future<bool> replayMutations(SyncEntity entity, int userId) async {
    final held = <int>{};
    for (final mutation in await database.getPendingMutations(userId, entity)) {
      final localId = mutation.localId;
      if (localId != null && held.contains(localId)) continue;
      if (mutation.failed) {
        if (localId != null) held.add(localId);
        continue;
      }

      final serverId = mutation.serverId ??
          (localId == null ? null : await database.serverIdForRow(entity, localId));
      if (serverId == null) {
        if (localId != null && await database.hasQueuedCreate(entity, localId)) {
          held.add(localId);
        } else {
          // Never reached the server and no longer exists here: nothing to do.
          await database.finishMutation(mutation);
        }
        continue;
      }

      try {
        await _send(entity, mutation, serverId);
        await database.finishMutation(mutation);
      } catch (error) {
        if (_isNotFound(error)) {
          await database.finishMutation(mutation);
          continue;
        }
        final transient = await _recordFailure(
          '${entity.name} ${mutation.op} ${mutation.id}',
          error,
          (message, failed) =>
              database.recordMutationAttempt(mutation.id, error: message, failed: failed),
        );
        if (transient) return true;
        if (localId != null) held.add(localId);
      }
    }
    return false;
  }

  /// Stores the failure; returns true if it was transient.
  Future<bool> _recordFailure(
    String what,
    Object error,
    Future<void> Function(String message, bool failed) record,
  ) async {
    final kind = classifySyncError(error);
    final message = describeSyncError(error);
    await record(message, kind == SyncErrorKind.permanent);
    if (kind == SyncErrorKind.transient) {
      log('Sync of $what paused: $message');
      return true;
    }
    log('Sync of $what refused: $message');
    return false;
  }

  bool _isNotFound(Object error) =>
      (error is DioException && error.response?.statusCode == 404) ||
      (error is SyncHttpException && error.statusCode == 404);

  Future<void> _send(SyncEntity entity, PendingMutation mutation, int serverId) async {
    final payload = _decode(mutation.payload);
    final Response response = switch ((entity, mutation.op)) {
      (SyncEntity.note, 'update') => await client.updateNote(
          UpdateNoteRequestDto.fromJson({...payload, 'noteId': serverId}),
        ),
      (SyncEntity.note, 'delete') => await client.deleteNote(serverId),
      (SyncEntity.task, 'update') => await client.updateTask(
          UpdateTaskRequestDto.fromJson({...payload, 'taskId': serverId}),
        ),
      (SyncEntity.task, 'status') => await client.toggleTaskStatus(
          serverId,
          status: payload['status'] as String?,
        ),
      (SyncEntity.task, 'delete') => await client.deleteTask(serverId),
      (SyncEntity.reminder, 'update') => await client.updateReminder(
          UpdateReminderRequestDto.fromJson({...payload, 'reminderId': serverId}),
        ),
      (SyncEntity.reminder, 'status') => await client.updateReminderStatus(
          serverId,
          status: payload['status'] as String?,
        ),
      (SyncEntity.reminder, 'delete') => await client.deleteReminder(serverId),
      _ => throw FormatException('Unknown change ${entity.name} ${mutation.op}'),
    };
    ensureSuccessStatus(response);
    final body = response.data;
    if (body is Map && body['success'] == false) {
      throw SyncRejectedException(
        body['message'] is String ? body['message'] as String : 'The server refused the change.',
      );
    }
  }

  Map<String, dynamic> _decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Queued payload must be an object.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  /// The queued payload, with the row's client id added for payloads written
  /// before client ids existed.
  Map<String, dynamic> _createPayload(String raw, String? clientId) {
    final payload = _decode(raw);
    if (clientId != null) payload['clientId'] ??= clientId;
    return payload;
  }

  Future<void> _uploadNote(PendingNote item) async {
    final request = CreateNoteRequestDto.fromJson(_createPayload(item.payload, item.clientId));
    final response = await client.createNote(request);
    await database.completePendingNote(
      queueId: item.id,
      localNoteId: item.localNoteId,
      serverId: _createdId(response, const ['noteId', 'id']),
      userId: item.userId,
      sentPayload: item.payload,
    );
  }

  Future<void> _uploadTask(PendingTask item) async {
    final request = CreateTaskRequestDto.fromJson(_createPayload(item.payload, item.clientId));
    final response = await client.createTask(request);
    await database.completePendingTask(
      queueId: item.id,
      localTaskId: item.localTaskId,
      serverId: _createdId(response, const ['taskId', 'id']),
      userId: item.userId,
      sentPayload: item.payload,
    );
  }

  Future<void> _uploadReminder(PendingReminder item) async {
    final request = CreateReminderRequestDto.fromJson(
      _createPayload(item.payload, item.clientId),
    );
    final response = await client.createReminder(request);
    await database.completePendingReminder(
      queueId: item.id,
      localReminderId: item.localReminderId,
      serverId: _createdId(response, const ['reminderId', 'id']),
      userId: item.userId,
      sentPayload: item.payload,
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
