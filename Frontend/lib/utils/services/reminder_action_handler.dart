import 'dart:async';
import 'dart:developer';

import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_scheduler.dart';

/// What [ReminderActionHandler.handle] did.
enum ReminderActionOutcome {
  /// Done / Not done saved.
  answered,

  /// Snoozed for [ReminderActionHandler.snoozeDuration].
  snoozed,

  /// The body was tapped: the app should ask "Did you complete it?".
  openPrompt,

  /// Not applied: not a reminder, another user, deleted, already answered
  /// or edited since (idempotency), or an unknown action.
  ignored,

  /// Something threw; it was logged.
  failed,
}

class ReminderActionResult {
  final ReminderActionOutcome outcome;

  /// The reminder before the action (for Undo and the prompt's title).
  final CachedReminder? before;

  /// The action that was applied (a [ReminderActions] id), if any.
  final String? actionId;

  const ReminderActionResult(this.outcome, {this.before, this.actionId});

  static const ignored = ReminderActionResult(ReminderActionOutcome.ignored);
}

/// REM-04: the one place a notification answer is applied, whether the app
/// is in the foreground, in the background or was killed (then it runs in
/// a background isolate, see notification_background.dart).
///
/// Idempotent by occurrence: an answer counts only for the occurrence the
/// reminder is still on, so a duplicated callback or a second device can't
/// apply it twice. Every write goes through the local-first repository
/// (Drift + outbox, FE-02), then the scheduler reconciles and a sync is
/// attempted without waiting long. Never throws.
///
/// "Not done" maps to MISSED. To change that decision (REJECTED, or leave it
/// PENDING), change [_notDoneStatus].
class ReminderActionHandler {
  static const snoozeDuration = Duration(minutes: 10);
  static const _notDoneStatus = 'MISSED';

  final AppDatabase database;
  final ReminderRepo repo;
  final ReminderScheduler scheduler;
  final int Function() currentUserId;

  /// Pushes queued changes to the server (OfflineSyncService.requestSync).
  final Future<void> Function()? pushChanges;
  final Duration syncTimeout;
  final DateTime Function() _now;

  ReminderActionHandler({
    required this.database,
    required this.repo,
    required this.scheduler,
    required this.currentUserId,
    this.pushChanges,
    this.syncTimeout = const Duration(seconds: 8),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Applies [actionId] (a [ReminderActions] id, or null for a tap on the
  /// notification body) to the reminder in [payload].
  Future<ReminderActionResult> handle(String? actionId, String? payload) async {
    try {
      final result = await _apply(actionId, payload);
      if (result.outcome == ReminderActionOutcome.answered ||
          result.outcome == ReminderActionOutcome.snoozed) {
        await scheduler.reconcile();
        await _push();
      }
      return result;
    } catch (error, stackTrace) {
      log('Failed to handle the reminder action $actionId: $error', stackTrace: stackTrace);
      return const ReminderActionResult(ReminderActionOutcome.failed);
    }
  }

  Future<ReminderActionResult> _apply(String? actionId, String? raw) async {
    final payload = ReminderPayload.tryParse(raw);
    if (payload == null) return ReminderActionResult.ignored;
    final userId = currentUserId();
    // Signed out, or someone else signed in, since it was shown.
    if (userId == 0 || payload.userId != userId) return ReminderActionResult.ignored;

    final row = await database.getReminderRow(userId, payload.localId) ??
        (payload.serverId == null
            ? null
            : await database.getReminderRowByServerId(userId, payload.serverId!));
    if (row == null) return ReminderActionResult.ignored; // deleted

    final action = (actionId == null || actionId.isEmpty) ? null : actionId;
    final repeating = row.repeatInterval != 'NONE';

    if (!sameWallClock(row.remindAt, payload.occurrence)) {
      return _lateAnswer(userId, row, action, payload.occurrence);
    }
    if (row.status != 'PENDING') {
      // Answered already (or completed in the app); a body tap still opens it.
      return action == null
          ? ReminderActionResult(ReminderActionOutcome.openPrompt, before: row)
          : ReminderActionResult.ignored;
    }

    switch (action) {
      case null:
        return ReminderActionResult(ReminderActionOutcome.openPrompt, before: row);
      case ReminderActions.done || ReminderActions.notDone:
        final outcome = action == ReminderActions.done ? 'COMPLETED' : _notDoneStatus;
        if (repeating) {
          await repo.completeOccurrence(userId, row, row.remindAt, outcome);
        } else {
          await repo.updateReminderStatus(userId, ReminderRepo.itemIdOf(row), outcome);
        }
        return ReminderActionResult(ReminderActionOutcome.answered, before: row, actionId: action);
      case ReminderActions.snooze:
        await repo.snoozeReminder(userId, row.id, _now().add(snoozeDuration));
        return ReminderActionResult(ReminderActionOutcome.snoozed, before: row, actionId: action);
      default:
        log('Unknown reminder action $action');
        return ReminderActionResult.ignored;
    }
  }

  /// The reminder has moved past [occurrence]. Usually the answer was already
  /// applied (ignore). One exception: a repeating occurrence that the app
  /// recorded as missed because nobody answered in time (catch-up, REM-05)
  /// still takes a late "Done" from the notification that is still showing.
  Future<ReminderActionResult> _lateAnswer(
    int userId,
    CachedReminder row,
    String? action,
    String occurrence,
  ) async {
    final caughtUp = row.repeatInterval != 'NONE' &&
        row.lastOutcome == 'MISSED' &&
        sameWallClock(row.lastOutcomeAt, occurrence);
    if (action == ReminderActions.done && caughtUp) {
      await repo.updateReminder(
        userId,
        UpdateReminderRequestDto(
          reminderId: ReminderRepo.itemIdOf(row),
          lastOutcome: 'COMPLETED',
          lastOutcomeAt: row.lastOutcomeAt,
        ),
      );
      return ReminderActionResult(ReminderActionOutcome.answered, before: row, actionId: action);
    }
    return ReminderActionResult.ignored;
  }

  /// Tries to upload now; the regular sync retries later if this fails.
  Future<void> _push() async {
    final push = pushChanges;
    if (push == null) return;
    try {
      await push().timeout(syncTimeout);
    } catch (error) {
      log('Reminder answer saved; it will sync later ($error)');
    }
  }

  /// Undo from the in-app snackbar: puts the reminder back as it was before
  /// [result] (status PENDING, and for repeats the answered occurrence). A
  /// repeating occurrence that is already in the past is then unanswered, so
  /// the next reconcile records it as missed and moves on (REM-05 catch-up).
  Future<void> undo(ReminderActionResult result) async {
    final before = result.before;
    if (before == null || result.outcome != ReminderActionOutcome.answered) return;
    final userId = currentUserId();
    if (userId == 0) return;
    try {
      final current = await database.getReminderRow(userId, before.id);
      if (current == null) return;
      final itemId = ReminderRepo.itemIdOf(current);
      if (before.repeatInterval == 'NONE') {
        await repo.updateReminderStatus(userId, itemId, 'PENDING');
      } else {
        await repo.updateReminder(
          userId,
          UpdateReminderRequestDto(
            reminderId: itemId,
            remindAt: before.remindAt,
            startAt: before.startAt ?? before.remindAt,
            status: 'PENDING',
            lastOutcome: before.lastOutcome,
            lastOutcomeAt: before.lastOutcomeAt,
          ),
        );
      }
      await scheduler.reconcile();
      await _push();
    } catch (error, stackTrace) {
      log('Failed to undo the reminder answer: $error', stackTrace: stackTrace);
    }
  }
}
