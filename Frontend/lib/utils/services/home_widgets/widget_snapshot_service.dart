import 'dart:async';
import 'dart:developer';

import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/utils/services/home_widgets/widget_host.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot.dart';
import 'package:timezone/timezone.dart' as tz;

/// Keeps the home-screen widgets (W-01) equal to the signed-in user's tasks
/// and reminders in Drift.
///
/// [refresh] builds a [WidgetSnapshot], saves it with home_widget and redraws
/// both widgets. It runs on: every change to the user's tasks or reminders
/// (debounced), login, app start and resume, sync completion and a day
/// change. Logout writes the signed-out snapshot ([showLoggedOut]).
///
/// Never throws: the widgets are a convenience and must not break the app.
class WidgetSnapshotService {
  final AppDatabase database;
  final WidgetHost host;
  final int Function() currentUserId;
  final tz.TZDateTime Function() _now;
  final Duration debounce;

  StreamSubscription<int>? _sessionSubscription;
  StreamSubscription<void>? _syncSubscription;
  final List<StreamSubscription<Object?>> _rowSubscriptions = [];
  int? _watchedUser;
  Timer? _debounceTimer;
  Timer? _dayTimer;
  Future<void>? _running;
  bool _runAgain = false;

  WidgetSnapshotService({
    required this.database,
    required this.host,
    required this.currentUserId,
    tz.TZDateTime Function()? now,
    this.debounce = const Duration(milliseconds: 500),
  }) : _now = now ?? (() => tz.TZDateTime.now(tz.local));

  /// Follows the session and the user's rows. [userChanges] is
  /// SessionService.changes (login / logout); [syncCompletions] fires after
  /// each sync pass.
  void start({Stream<int>? userChanges, Stream<void>? syncCompletions}) {
    if (!host.isSupported) return;
    _watch(currentUserId());
    _sessionSubscription ??= userChanges?.listen((userId) {
      _watch(userId);
      unawaited(refresh());
    });
    _syncSubscription ??= syncCompletions?.listen((_) => _requestDebounced());
    _armDayTimer();
    unawaited(refresh());
  }

  /// App back in the foreground (the day or time zone may have changed).
  Future<void> onAppResumed() {
    _armDayTimer();
    return refresh();
  }

  void _watch(int userId) {
    if (_watchedUser == userId) return;
    _stopWatching();
    _watchedUser = userId;
    if (userId == 0) return;
    void onError(Object error, StackTrace stackTrace) =>
        log('Widget watch failed: $error', stackTrace: stackTrace);
    _rowSubscriptions
      ..add(database.watchTasksForUser(userId).listen((_) => _requestDebounced(), onError: onError))
      ..add(database.watchRemindersForUser(userId).listen((_) => _requestDebounced(), onError: onError));
  }

  void _stopWatching() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    for (final subscription in _rowSubscriptions) {
      unawaited(subscription.cancel());
    }
    _rowSubscriptions.clear();
    _watchedUser = null;
  }

  void _requestDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(refresh()));
  }

  /// "Today" and "overdue" change at midnight even if nothing else does.
  void _armDayTimer() {
    _dayTimer?.cancel();
    final now = _now();
    final midnight = tz.TZDateTime(now.location, now.year, now.month, now.day + 1);
    // A second past midnight, so the new day has surely started.
    _dayTimer = Timer(midnight.difference(now) + const Duration(seconds: 1), () {
      unawaited(refresh());
      _armDayTimer();
    });
  }

  /// Writes the current snapshot and redraws the widgets. Calls while one
  /// runs are folded into one more pass.
  Future<void> refresh() {
    if (!host.isSupported) return Future.value();
    final running = _running;
    if (running != null) {
      _runAgain = true;
      return running;
    }
    final run = _loop();
    _running = run;
    return run;
  }

  Future<void> _loop() async {
    try {
      do {
        _runAgain = false;
        await _write(await buildSnapshot());
      } while (_runAgain);
    } catch (error, stackTrace) {
      log('Widget refresh failed: $error', stackTrace: stackTrace);
    } finally {
      _running = null;
    }
  }

  /// The snapshot for whoever is signed in now.
  Future<WidgetSnapshot> buildSnapshot() async {
    final userId = currentUserId();
    final now = _now();
    if (userId == 0) return WidgetSnapshot.loggedOut(now);
    final tasks = await database.getTasksForUser(userId);
    final reminders = await database.getRemindersForUser(userId);
    final recentlyDone = WidgetSnapshot.decodeRecentlyDone(
      await host.readString(WidgetSnapshot.recentlyDoneKey),
      now,
    );
    // Signed out while reading: don't show the old user's items.
    if (currentUserId() != userId) return WidgetSnapshot.loggedOut(now);
    return WidgetSnapshot.build(
      tasks: tasks,
      reminders: reminders,
      now: now,
      recentlyDone: recentlyDone,
    );
  }

  /// W-02: [taskId] was ticked on the widget. Keeps it on the widget, done,
  /// for a moment (see [WidgetSnapshot.recentlyDoneWindow]).
  Future<void> markTickedOnWidget(int taskId) async {
    if (!host.isSupported) return;
    final now = _now();
    final entries = WidgetSnapshot.decodeRecentlyDone(
      await host.readString(WidgetSnapshot.recentlyDoneKey),
      now,
    )..[taskId] = now.toUtc();
    await host.saveString(WidgetSnapshot.recentlyDoneKey, WidgetSnapshot.encodeRecentlyDone(entries));
  }

  /// Logout hook: the widgets show "Sign in to Daymark" and nothing of the
  /// signed-out user. Waits for a refresh that is still running so it can't
  /// write the old user's snapshot afterwards.
  Future<void> showLoggedOut() async {
    if (!host.isSupported) return;
    _stopWatching();
    await _running;
    try {
      await host.saveString(WidgetSnapshot.recentlyDoneKey, null);
      // Taps on the signed-out user's widgets are not applied for anyone else.
      await host.saveString(DaymarkWidgets.pendingActionsKey, null);
      for (final key in DaymarkWidgets.optimisticKeys) {
        await host.saveString(key, null);
      }
      await _write(WidgetSnapshot.loggedOut(_now()));
    } catch (error, stackTrace) {
      log('Failed to clear the widgets: $error', stackTrace: stackTrace);
    }
  }

  Future<void> _write(WidgetSnapshot snapshot) async {
    await host.saveString(WidgetSnapshot.storageKey, snapshot.encode());
    await host.updateAll();
    // A second late, so the redraw surely sees the reminder as passed.
    await host.scheduleReminderRefreshes([
      for (final reminder in snapshot.reminders) reminder.fireAt.add(const Duration(seconds: 1)),
    ]);
  }

  Future<void> dispose() async {
    _stopWatching();
    _dayTimer?.cancel();
    _dayTimer = null;
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
    await _syncSubscription?.cancel();
    _syncSubscription = null;
    await _running;
  }
}
