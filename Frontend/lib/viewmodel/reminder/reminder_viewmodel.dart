import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/viewmodel/reminder/reminder_state.dart';
import 'package:notes_app/viewmodel/controllers.dart';

class ReminderViewmodel extends AsyncNotifier<ReminderState> {
  final ReminderRepo _reminderRepo = getIt<ReminderRepo>();

  @override
  Future<ReminderState> build() async {
    final userId = ref.watch(sessionUserIdProvider);
    final cached = await _reminderRepo.getCachedReminders(userId);

    final subscription = _reminderRepo.watchReminders(userId).listen((reminders) {
      if (state.hasValue) {
        state = AsyncData(state.value!.copyWith(reminders: reminders));
      }
    }, onError: (Object err, StackTrace st) {
      log('Failed to watch reminders: $err', stackTrace: st);
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    if (userId != 0) {
      unawaited(_refreshReminders(userId));
    }

    return ReminderState(reminders: cached);
  }

  int getUserId() {
    return ref.read(sessionUserIdProvider);
  }

  Future<void> refreshReminders() async {
    final userId = getUserId();
    if (userId != 0) {
      await _reminderRepo.fetchAndCacheReminders(userId);
    }
  }

  Future<void> _refreshReminders(int userId) async {
    try {
      await _reminderRepo.fetchAndCacheReminders(userId);
    } catch (e, st) {
      log('Failed to fetch reminders: $e', stackTrace: st);
    }
  }

  Future<void> createReminder({
    required String title,
    required String remindAt,
    String? dueDate,
    String? dueTime,
    String? category,
    String? repeatInterval,
  }) async {
    final userId = getUserId();
    final request = CreateReminderRequestDto(
      userId: userId,
      title: title,
      remindAt: remindAt,
      dueDate: dueDate,
      dueTime: dueTime,
      category: category,
      repeatInterval: repeatInterval,
    );

    await _reminderRepo.enqueueReminder(request);
  }

  Future<void> updateReminderStatus(int reminderId, String status) async {
    final userId = getUserId();
    await _reminderRepo.updateReminderStatus(userId, reminderId, status);
  }

  Future<void> updateReminder(UpdateReminderRequestDto requestDto) async {
    final userId = getUserId();
    await _reminderRepo.updateReminder(userId, requestDto);
  }

  Future<void> deleteReminder(int reminderId) async {
    final userId = getUserId();
    await _reminderRepo.deleteReminder(userId, reminderId);
  }
}
