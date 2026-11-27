import 'dart:async';
import 'dart:developer';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:notes_app/utils/services/background_graph.dart';
import 'package:notes_app/utils/services/home_widgets/widget_host.dart';
import 'package:notes_app/utils/services/home_widgets/widget_inbox.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';
import 'package:notes_app/utils/services/reminder_scheduler.dart';

/// A button on a home-screen widget that changes data without opening the
/// app (W-02):
///
/// - `daymark://widget/toggle-task?id=<id>`: completes the task.
/// - `daymark://widget/reminder-done?id=<id>&occurrence=<wall clock>`:
///   answers that occurrence Done, exactly like the notification's Done.
/// - `daymark://widget/import-inbox`: imports tasks added through the iOS
///   App Intent (W-03, [WidgetTaskInbox]).
///
/// Ids are the app's item ids (server id, or minus the local id); a local id
/// still matches after the item got its server id.
sealed class WidgetAction {
  const WidgetAction();

  static WidgetAction? parse(Uri? uri) {
    if (uri == null || uri.scheme.toLowerCase() != 'daymark' || uri.host.toLowerCase() != 'widget') {
      return null;
    }
    final path = uri.pathSegments.where((s) => s.isNotEmpty).firstOrNull;
    if (path == 'import-inbox') return const ImportInboxAction();
    final id = int.tryParse(uri.queryParameters['id'] ?? '');
    if (id == null || id == 0) return null;
    switch (path) {
      case 'toggle-task':
        return ToggleTaskAction(id);
      case 'reminder-done':
        final occurrence = uri.queryParameters['occurrence'];
        if (parseWallClock(occurrence) == null) return null;
        return ReminderDoneAction(id, occurrence!);
      default:
        return null;
    }
  }
}

final class ToggleTaskAction extends WidgetAction {
  final int id;
  const ToggleTaskAction(this.id);
}

final class ReminderDoneAction extends WidgetAction {
  final int id;
  final String occurrence;
  const ReminderDoneAction(this.id, this.occurrence);
}

final class ImportInboxAction extends WidgetAction {
  const ImportInboxAction();
}

enum WidgetActionOutcome {
  /// Saved locally and queued for the server.
  applied,

  /// Nothing to do: unknown link, signed out, deleted, or already applied
  /// (a repeated tap, or a second device).
  ignored,

  /// Something threw; it was logged.
  failed,
}

/// Applies a [WidgetAction] the way the app would: local first through the
/// repositories and the outbox, then the reminder notifications reconcile,
/// a short sync is tried, and the widgets are redrawn. Idempotent; never
/// throws.
class WidgetActionHandler {
  final AppDatabase database;
  final TaskRepo taskRepo;
  final ReminderScheduler scheduler;
  final ReminderActionHandler reminderActions;
  final WidgetSnapshotService widgets;
  final int Function() currentUserId;

  /// For [ImportInboxAction]; without it that action is ignored.
  final WidgetTaskInbox? inbox;

  /// Pushes queued changes to the server (OfflineSyncService.requestSync).
  final Future<void> Function()? pushChanges;
  final Duration syncTimeout;

  WidgetActionHandler({
    required this.database,
    required this.taskRepo,
    required this.scheduler,
    required this.reminderActions,
    required this.widgets,
    required this.currentUserId,
    this.inbox,
    this.pushChanges,
    this.syncTimeout = const Duration(seconds: 8),
  });

  Future<WidgetActionOutcome> handle(Uri? uri) async {
    final action = WidgetAction.parse(uri);
    if (action == null) {
      log('Ignoring the widget action $uri');
      return WidgetActionOutcome.ignored;
    }
    try {
      final outcome = switch (action) {
        ToggleTaskAction(:final id) => await _completeTask(id),
        ReminderDoneAction(:final id, :final occurrence) => await _reminderDone(id, occurrence),
        ImportInboxAction() => await _importInbox(),
      };
      return outcome;
    } catch (error, stackTrace) {
      log('Widget action $uri failed: $error', stackTrace: stackTrace);
      return WidgetActionOutcome.failed;
    } finally {
      // Even an ignored tap redraws: the widget may be showing stale data.
      await widgets.refresh();
    }
  }

  Future<WidgetActionOutcome> _completeTask(int id) async {
    final userId = currentUserId();
    if (userId == 0) return WidgetActionOutcome.ignored;
    final row = (await database.getTasksForUser(userId))
        .where((t) => t.serverId == id || -t.id == id)
        .firstOrNull;
    // Deleted, or already done: a second tap must not undo the first.
    if (row == null || row.isCompleted || row.status == 'COMPLETED') {
      return WidgetActionOutcome.ignored;
    }
    await taskRepo.setTaskStatus(userId, row.serverId ?? -row.id, 'COMPLETED');
    // Keyed by the local id, which doesn't change when the server id arrives.
    await widgets.markTickedOnWidget(-row.id);
    await _push();
    return WidgetActionOutcome.applied;
  }

  Future<WidgetActionOutcome> _reminderDone(int id, String occurrence) async {
    final userId = currentUserId();
    if (userId == 0) return WidgetActionOutcome.ignored;
    final row = (await database.getRemindersForUser(userId))
        .where((r) => r.serverId == id || -r.id == id)
        .firstOrNull;
    if (row == null) return WidgetActionOutcome.ignored;
    // Repeats the app hasn't caught up (it may not have run since an
    // occurrence passed) move on first, so the stored occurrence is the one
    // the widget shows.
    await scheduler.reconcile();
    final payload = ReminderPayload(
      userId: userId,
      localId: row.id,
      serverId: row.serverId,
      occurrence: occurrence,
      fireAt: '',
    );
    // The notification's Done: one-off → COMPLETED, repeating → next
    // occurrence; it reconciles and syncs itself.
    final result = await reminderActions.handle(ReminderActions.done, payload.encode());
    return switch (result.outcome) {
      ReminderActionOutcome.answered => WidgetActionOutcome.applied,
      ReminderActionOutcome.failed => WidgetActionOutcome.failed,
      _ => WidgetActionOutcome.ignored,
    };
  }

  Future<WidgetActionOutcome> _importInbox() async {
    final importer = inbox;
    if (importer == null) return WidgetActionOutcome.ignored;
    final added = await importer.importAll();
    if (added == 0) return WidgetActionOutcome.ignored;
    await _push();
    return WidgetActionOutcome.applied;
  }

  /// Tries to upload now; the app's sync retries later if this fails.
  Future<void> _push() async {
    final push = pushChanges;
    if (push == null) return;
    try {
      await push().timeout(syncTimeout);
    } catch (error) {
      log('Widget change saved; it will sync later ($error)');
    }
  }
}

/// Widget actions arriving while one is handled wait for it.
Future<void> _queue = Future.value();

/// W-02: home_widget calls this in a background isolate when a widget
/// button with a `daymark://widget/...` link is tapped (Android: Glance
/// action → WorkManager; iOS 17: the BackgroundIntent). Registered with
/// `HomeWidget.registerInteractivityCallback` in main.dart.
@pragma('vm:entry-point')
Future<void> widgetInteractivityCallback(Uri? uri) {
  final run = _queue.then((_) => _handleInBackground(uri));
  _queue = run;
  return run;
}

Future<void> _handleInBackground(Uri? uri) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final graph = await BackgroundGraph.open();
    try {
      final widgets = WidgetSnapshotService(
        database: graph.database,
        host: HomeWidgetHost(),
        currentUserId: () => graph.userId,
      );
      final handler = WidgetActionHandler(
        database: graph.database,
        taskRepo: graph.taskRepo,
        scheduler: graph.scheduler,
        reminderActions: graph.reminderActions,
        widgets: widgets,
        currentUserId: () => graph.userId,
        inbox: WidgetTaskInbox(
          host: HomeWidgetHost(),
          repo: graph.taskRepo,
          currentUserId: () => graph.userId,
        ),
        pushChanges: () {
          graph.sync.setUserId(graph.userId);
          return graph.sync.requestSync();
        },
      );
      final outcome = await handler.handle(uri);
      log('Widget action $uri: ${outcome.name}');
    } finally {
      await graph.close();
    }
  } catch (error, stackTrace) {
    // A crash here would lose the tap silently: always log it.
    log('Background widget action failed: $error', stackTrace: stackTrace);
  }
}
