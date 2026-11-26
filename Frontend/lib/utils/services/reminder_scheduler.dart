import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/utils/reminder_time.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// The JSON payload of a reminder notification (REM-00). [occurrence] makes
/// answering idempotent: an answer for an occurrence the reminder has moved
/// past is ignored (REM-04).
@immutable
class ReminderPayload {
  static const version = 1;
  static const type = 'reminder';

  final int userId;
  final int localId;
  final int? serverId;
  final String occurrence;
  final String fireAt;

  const ReminderPayload({
    required this.userId,
    required this.localId,
    required this.serverId,
    required this.occurrence,
    required this.fireAt,
  });

  String encode() => jsonEncode({
    'v': version,
    'type': type,
    'userId': userId,
    'localId': localId,
    'serverId': serverId,
    'occurrence': occurrence,
    'fireAt': fireAt,
  });

  /// Null for anything that isn't a version-1 reminder payload (digests,
  /// the debug test notification, garbage).
  static ReminderPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map || json['type'] != type || json['v'] != version) return null;
      final userId = json['userId'];
      final localId = json['localId'];
      final occurrence = json['occurrence'];
      if (userId is! int || localId is! int || occurrence is! String) return null;
      final serverId = json['serverId'];
      return ReminderPayload(
        userId: userId,
        localId: localId,
        serverId: serverId is int ? serverId : null,
        occurrence: occurrence,
        fireAt: json['fireAt']?.toString() ?? '',
      );
    } on FormatException {
      return null;
    }
  }
}

/// A notification reconcile wants the OS to have.
@immutable
class _Desired {
  final int id;
  final tz.TZDateTime at;
  final String title;
  final String body;
  final String payload;

  const _Desired(this.id, this.at, this.title, this.body, this.payload);
}

/// REM-03: keeps the OS's scheduled notifications equal to the reminders in
/// Drift, whatever changed them (create, edit, delete, status, snooze, sync,
/// refresh, login, logout, time zone).
///
/// [reconcile] builds the wanted set from the database and applies only the
/// difference to `pendingNotificationRequests()`, so it is idempotent and
/// safe to call often. One notification per reminder (its next fire time),
/// with the notification id = the reminder's local id. Only the nearest
/// [maxScheduled] are scheduled (iOS keeps at most 64 pending); later ones
/// are scheduled as earlier ones are handled.
class ReminderScheduler {
  /// Leaves room under iOS's 64 for the digests and snoozes.
  static const maxScheduled = 50;

  final AppDatabase database;
  final ReminderRepo repo;
  final NotificationService notifications;
  final int Function() currentUserId;
  final tz.TZDateTime Function() _now;
  final bool Function() _use24h;
  final Duration debounce;

  StreamSubscription<int>? _sessionSubscription;
  StreamSubscription<List<CachedReminder>>? _rowsSubscription;
  ValueListenable<NotificationStatus>? _permission;
  bool _alertsOn = false;
  int? _watchedUser;
  Timer? _debounceTimer;
  Future<void>? _running;
  bool _runAgain = false;

  ReminderScheduler({
    required this.database,
    required this.repo,
    required this.notifications,
    required this.currentUserId,
    tz.TZDateTime Function()? now,
    bool Function()? use24h,
    this.debounce = const Duration(milliseconds: 500),
  }) : _now = now ?? (() => tz.TZDateTime.now(tz.local)),
       _use24h = use24h ?? (() => PlatformDispatcher.instance.alwaysUse24HourFormat);

  /// Follows the signed-in user's reminders: every change on their watch
  /// stream (debounced) reconciles, and so does permission becoming granted.
  void start({Stream<int>? userChanges, ValueListenable<NotificationStatus>? permission}) {
    _watch(currentUserId());
    _sessionSubscription ??= userChanges?.listen(_watch);
    if (permission != null && _permission == null) {
      _permission = permission;
      _alertsOn = permission.value.alertsOn;
      permission.addListener(_onPermissionChanged);
    }
  }

  void _onPermissionChanged() {
    final on = _permission!.value.alertsOn;
    if (on && !_alertsOn) unawaited(reconcile());
    _alertsOn = on;
  }

  void _watch(int userId) {
    if (_watchedUser == userId) return;
    _stopWatching();
    _watchedUser = userId;
    if (userId == 0) return;
    _rowsSubscription = database.watchRemindersForUser(userId).listen(
      (_) => _requestDebounced(),
      onError: (Object error, StackTrace stackTrace) =>
          log('Reminder watch failed: $error', stackTrace: stackTrace),
    );
  }

  void _stopWatching() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    unawaited(_rowsSubscription?.cancel());
    _rowsSubscription = null;
    _watchedUser = null;
  }

  void _requestDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(reconcile()));
  }

  /// App back in the foreground: the user may have travelled (time zone)
  /// or the app may have been closed past some occurrences.
  Future<void> onAppResumed() async {
    try {
      await notifications.refreshTimezone();
    } catch (error) {
      log('Could not refresh the time zone: $error');
    }
    await reconcile();
  }

  /// Makes the OS match the database. Calls while one runs are folded into
  /// one more pass. Never throws.
  Future<void> reconcile() {
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
        await _reconcileOnce();
      } while (_runAgain);
    } catch (error, stackTrace) {
      log('Reminder reconcile failed: $error', stackTrace: stackTrace);
    } finally {
      _running = null;
    }
  }

  Future<void> _reconcileOnce() async {
    if (!notifications.isSupported) return;
    final userId = currentUserId();
    if (userId == 0) return;
    // Without permission nothing would show; keep what is scheduled, it
    // works again as soon as permission is back.
    if (!await notifications.areEnabled()) return;

    final now = _now();
    var rows = await database.getRemindersForUser(userId);
    if (await _catchUp(userId, rows, now)) {
      rows = await database.getRemindersForUser(userId);
    }

    final use24h = _use24h();
    final wanted = <_Desired>[];
    for (final row in rows) {
      final desired = _desiredFor(userId, row, now, use24h);
      if (desired != null) wanted.add(desired);
    }
    wanted.sort((a, b) => a.at.compareTo(b.at));
    final desired = {for (final d in wanted.take(maxScheduled)) d.id: d};

    final scheduled = <int, ({String? title, String? body, String? payload})>{};
    for (final request in await notifications.pending()) {
      if (ReminderPayload.tryParse(request.payload) == null) continue; // digests etc.
      scheduled[request.id] = (title: request.title, body: request.body, payload: request.payload);
    }

    for (final MapEntry(key: id) in scheduled.entries) {
      if (!desired.containsKey(id)) await notifications.cancel(id);
    }
    for (final want in desired.values) {
      final have = scheduled[want.id];
      if (have != null &&
          have.payload == want.payload &&
          have.title == want.title &&
          have.body == want.body) {
        continue;
      }
      // Logged out while reconciling: schedule nothing for the old user.
      if (currentUserId() != userId) return;
      await notifications.schedule(
        id: want.id,
        at: want.at,
        title: want.title,
        body: want.body,
        payload: want.payload,
      );
    }
  }

  /// REM-05: repeating reminders whose occurrence passed unanswered move to
  /// their next future occurrence (recorded as missed) instead of firing a
  /// burst of old notifications. Returns true if anything moved.
  Future<bool> _catchUp(int userId, List<CachedReminder> rows, tz.TZDateTime now) async {
    final nowWall = wallClockOf(now);
    var moved = false;
    for (final row in rows) {
      if (row.status != 'PENDING' || row.repeatInterval == 'NONE') continue;
      final at = parseWallClock(row.remindAt);
      if (at == null || at.isAfter(nowWall)) continue;
      if (_snoozedUntil(row)?.isAfter(now) ?? false) continue;
      final next = nextOccurrence(
        start: parseWallClock(row.startAt) ?? at,
        interval: row.repeatInterval,
        after: nowWall,
      );
      if (next == null) continue;
      await repo.advanceMissedOccurrence(userId, row, next);
      moved = true;
    }
    return moved;
  }

  _Desired? _desiredFor(int userId, CachedReminder row, tz.TZDateTime now, bool use24h) {
    if (row.status != 'PENDING') return null;
    final at = parseWallClock(row.remindAt);
    if (at == null) return null;
    final snoozed = _snoozedUntil(row);
    final isSnoozed = snoozed != null && snoozed.isAfter(now);
    final fireAt = isSnoozed ? snoozed : toTz(at, tz.local);
    if (!fireAt.isAfter(now)) return null;

    final category = row.category?.trim();
    final body = [
      if (isSnoozed) 'Snoozed',
      'Due ${formatDue(at, use24h: use24h)}',
      if (category != null && category.isNotEmpty) category,
      ?repeatLabel(row.repeatInterval),
    ].join(' · ');
    final payload = ReminderPayload(
      userId: userId,
      localId: row.id,
      serverId: row.serverId,
      occurrence: row.remindAt,
      fireAt: fireAt.toIso8601String(),
    );
    return _Desired(row.id, fireAt, row.title, body, payload.encode());
  }

  static tz.TZDateTime? _snoozedUntil(CachedReminder row) {
    final instant = DateTime.tryParse(row.snoozedUntil ?? '');
    return instant == null ? null : tz.TZDateTime.from(instant, tz.local);
  }

  /// Logout: no notification of the signed-out user may fire. Waits for a
  /// reconcile that is still running so it can't schedule afterwards.
  Future<void> cancelAllReminders() async {
    _stopWatching();
    await _running;
    for (final request in await notifications.pending()) {
      if (ReminderPayload.tryParse(request.payload) != null) {
        await notifications.cancel(request.id);
      }
    }
  }

  Future<void> dispose() async {
    _stopWatching();
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
    _permission?.removeListener(_onPermissionChanged);
    _permission = null;
    await _running;
  }
}
