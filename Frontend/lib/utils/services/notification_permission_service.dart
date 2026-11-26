import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/utils/services/notification_service.dart';

/// Whether Daymark may post notifications.
enum NotificationPermission {
  granted,

  /// Asked and refused; asking again may still work (Android).
  denied,

  /// Refused for good: only the OS settings can turn it back on (iOS, macOS).
  permanentlyDenied,

  /// Never asked.
  notDetermined,

  /// Web, Windows, Linux.
  unsupported,
}

/// What the notification settings row, the Workspace banner and the
/// reminder cards show.
@immutable
class NotificationStatus {
  final NotificationPermission permission;

  /// Android 12+: exact alarms allowed. Always true elsewhere.
  final bool exactAllowed;

  const NotificationStatus(this.permission, {this.exactAllowed = true});

  static const unknown = NotificationStatus(NotificationPermission.notDetermined);

  bool get isSupported => permission != NotificationPermission.unsupported;
  bool get alertsOn => permission == NotificationPermission.granted;

  /// Notifications are on but the OS may deliver them a few minutes late.
  bool get mayBeLate => alertsOn && !exactAllowed;

  /// Reminders exist but won't alert (the banner and the struck-out bell).
  bool get alertsOff => isSupported && !alertsOn;

  @override
  bool operator ==(Object other) =>
      other is NotificationStatus &&
      other.permission == permission &&
      other.exactAllowed == exactAllowed;

  @override
  int get hashCode => Object.hash(permission, exactAllowed);

  @override
  String toString() => 'NotificationStatus($permission, exact: $exactAllowed)';
}

/// REM-02: asks for notification permission in context (when the first
/// reminder is saved), never at launch, and tracks the result.
///
/// The OS doesn't say whether it was ever asked, so that is remembered in
/// [Preference]. [status] is refreshed on every app resume; listeners (the
/// reminder scheduler, REM-03) react when it turns granted.
class NotificationPermissionService {
  static const askedKey = 'notification_permission_asked';
  static const prePromptShownAtKey = 'notification_preprompt_shown_at';

  /// "Not now" on the pre-prompt is respected for this long.
  static const prePromptCooldown = Duration(days: 30);

  final NotificationService notifications;
  final Preference preference;
  final bool _permissionIsFinal;

  /// The last known status; starts as [NotificationStatus.unknown].
  final ValueNotifier<NotificationStatus> status = ValueNotifier(NotificationStatus.unknown);

  /// [permissionIsFinal]: a refusal can't be asked again (iOS and macOS).
  NotificationPermissionService({
    required this.notifications,
    required this.preference,
    bool? permissionIsFinal,
  }) : _permissionIsFinal =
           permissionIsFinal ??
           (!kIsWeb &&
               (defaultTargetPlatform == TargetPlatform.iOS ||
                   defaultTargetPlatform == TargetPlatform.macOS));

  bool get _asked => preference.getBool(askedKey) ?? false;

  /// Reads the current permission from the OS and publishes it in [status].
  Future<NotificationStatus> refresh() async {
    final next = await _read();
    status.value = next;
    return next;
  }

  Future<NotificationStatus> _read() async {
    if (!notifications.isSupported) {
      return const NotificationStatus(NotificationPermission.unsupported);
    }
    try {
      if (await notifications.areEnabled()) {
        return NotificationStatus(
          NotificationPermission.granted,
          exactAllowed: await notifications.canScheduleExact(),
        );
      }
      if (!_asked) return const NotificationStatus(NotificationPermission.notDetermined);
      return NotificationStatus(
        _permissionIsFinal ? NotificationPermission.permanentlyDenied : NotificationPermission.denied,
      );
    } catch (error) {
      // A plugin failure must never break the screen that asked.
      log('Could not read the notification permission: $error');
      return status.value;
    }
  }

  /// Shows the OS prompt. Returns true if notifications are allowed after it.
  Future<bool> request() async {
    if (!notifications.isSupported) return false;
    await preference.setBool(askedKey, true);
    try {
      await notifications.requestPermission();
    } catch (error) {
      log('The notification permission request failed: $error');
    }
    return (await refresh()).alertsOn;
  }

  /// Whether to show the Daymark pre-prompt before the OS prompt: only while
  /// the OS was never asked, and at most once per [prePromptCooldown].
  Future<bool> shouldShowPrePrompt({DateTime? now}) async {
    final current = await refresh();
    if (current.permission != NotificationPermission.notDetermined) return false;
    final shownAt = DateTime.tryParse(preference.getString(prePromptShownAtKey) ?? '');
    if (shownAt == null) return true;
    return (now ?? DateTime.now()).difference(shownAt) >= prePromptCooldown;
  }

  Future<void> markPrePromptShown({DateTime? now}) =>
      preference.setString(prePromptShownAtKey, (now ?? DateTime.now()).toIso8601String());

  /// Android 12+: opens the "Alarms & reminders" setting. The answer is
  /// picked up by the [refresh] on the next app resume.
  Future<void> requestExact() async {
    try {
      await notifications.requestExact();
    } catch (error) {
      log('Could not open the exact alarm setting: $error');
    }
  }

  /// Opens the OS notification settings for Daymark.
  Future<void> openSettings() async {
    try {
      await notifications.openSettings();
    } catch (error) {
      log('Could not open the notification settings: $error');
    }
  }

  /// The settings row's action: ask if possible, otherwise open the OS
  /// settings (refused for good, or the prompt didn't grant it).
  Future<void> enable() async {
    final current = await refresh();
    switch (current.permission) {
      case NotificationPermission.granted:
        if (!current.exactAllowed) await requestExact();
      case NotificationPermission.notDetermined:
      case NotificationPermission.denied:
        if (!await request()) await openSettings();
      case NotificationPermission.permanentlyDenied:
        await openSettings();
      case NotificationPermission.unsupported:
        break;
    }
  }
}
