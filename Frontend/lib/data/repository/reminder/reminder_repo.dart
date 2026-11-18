import 'dart:convert';

import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/reminder_database_mapper.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';

class ReminderRepo {
  final ApiClient client;
  final AppDatabase database;

  ReminderRepo({required this.client, required this.database});

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

  Future<int> enqueueReminder(CreateReminderRequestDto requestDto) {
    final userId = requestDto.userId;
    final title = requestDto.title;
    if (title.trim().isEmpty) {
      throw ArgumentError('A reminder requires a title.');
    }

    return database.enqueueReminder(
      userId: userId,
      title: title,
      remindAt: requestDto.remindAt,
      dueDate: requestDto.dueDate,
      dueTime: requestDto.dueTime,
      category: requestDto.category ?? 'General',
      status: requestDto.status ?? 'PENDING',
      repeatInterval: requestDto.repeatInterval ?? 'NONE',
      payload: jsonEncode(requestDto.toJson()),
    );
  }

  Future<void> syncQueuedReminders(int userId) async {
    final pendingList = await database.getPendingReminders(userId);
    for (final pending in pendingList) {
      try {
        final decoded = jsonDecode(pending.payload);
        if (decoded is! Map) continue;

        final request = CreateReminderRequestDto.fromJson(
          Map<String, dynamic>.from(decoded),
        );

        final response = await client.createReminder(request);
        if (response.statusCode == null ||
            response.statusCode! < 200 ||
            response.statusCode! >= 300) {
          continue;
        }

        final body = response.data;
        int? serverId;
        if (body is Map && body['data'] is Map) {
          final data = body['data'] as Map;
          final rawId = data['reminderId'] ?? data['id'];
          if (rawId is int) {
            serverId = rawId;
          } else if (rawId is String) {
            serverId = int.tryParse(rawId);
          }
        }

        if (serverId != null) {
          await database.completePendingReminder(
            queueId: pending.id,
            localReminderId: pending.localReminderId,
            serverId: serverId,
          );
        }
      } catch (_) {
        // Network or server error; keep in queue for next sync
        break;
      }
    }
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
