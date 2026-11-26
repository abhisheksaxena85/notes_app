import 'dart:async';
import 'dart:convert';

import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/reminder_database_mapper.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
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

  Future<List<ReminderItem>> fetchAndCacheReminders(int userId) async {
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
    final localId = await database.enqueueReminder(
      userId: userId,
      title: title,
      remindAt: requestDto.remindAt,
      dueDate: requestDto.dueDate,
      dueTime: requestDto.dueTime,
      category: requestDto.category ?? 'General',
      status: requestDto.status ?? 'PENDING',
      repeatInterval: requestDto.repeatInterval ?? 'NONE',
      clientId: clientId,
      payload: jsonEncode({...requestDto.toJson(), 'clientId': clientId}),
    );
    unawaited(syncService.requestSync());
    return localId;
  }

  Future<void> updateReminderStatus(int userId, int reminderId, String status) async {
    await database.transaction(() async {
      await database.updateReminderStatus(
        reminderId: reminderId,
        status: status,
      );
      // Not synced yet: keep the queued create payload in step (see TaskRepo).
      if (reminderId < 0) {
        final pending = await database.getPendingReminderForLocalId(-reminderId);
        if (pending != null) {
          final decoded = jsonDecode(pending.payload);
          if (decoded is Map) {
            final payload = Map<String, dynamic>.from(decoded)..['status'] = status;
            await database.updatePendingReminderPayload(
              pending.id,
              jsonEncode(payload),
            );
          }
        }
      }
    });

    if (reminderId > 0) {
      try {
        await client.updateReminderStatus(reminderId, status: status);
      } catch (_) {
        // Ignored for offline tolerance
      }
    }
  }

  Future<void> updateReminder(int userId, UpdateReminderRequestDto requestDto) async {
    if (requestDto.reminderId > 0) {
      final response = await client.updateReminder(requestDto);
      if (response.statusCode == 200 && response.data is Map) {
        final body = response.data as Map;
        if (body['data'] is Map) {
          final updated = ReminderItem.fromJson(Map<String, dynamic>.from(body['data']));
          await database.saveServerReminder(
            ReminderDatabaseMapper.fromReminderItem(userId, updated),
          );
        }
      }
    }
  }

  Future<void> deleteReminder(int userId, int reminderId) async {
    await database.deleteCachedReminder(reminderId);
    if (reminderId > 0) {
      try {
        await client.deleteReminder(reminderId);
      } catch (_) {
        // Ignored for offline tolerance
      }
    }
  }

  Future<List<ReminderItem>> getRemindersByDate(int userId, String date) async {
    final cached = await database.getRemindersByDate(userId, date);
    return cached.map(ReminderDatabaseMapper.toReminderItem).toList();
  }
}
