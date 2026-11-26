# REM-02 — Permission flow: notifications and exact alarms

**Type:** Feature · **Priority:** P1 · **Area:** Frontend · **Depends on:** REM-01 · **Read:** REM-00

## Why
- Android 13+ needs the runtime `POST_NOTIFICATIONS` permission. Without it nothing shows.
- On Android 12+ exact alarms (`SCHEDULE_EXACT_ALARM`) can be off. From Android 14 they're **off by default** for new installs. Without them reminders can be late by several minutes (inexact mode).
- iOS needs `requestPermissions(alert, badge, sound)`. If the user says no, iOS won't ask again; they have to go to Settings.

## UX
1. **Ask in context, not at launch.** The first time the user saves a reminder (`create_reminder_modal.dart` `_saveReminder`), and only if permission hasn't been decided yet:
   - Show a short Daymark-styled pre-prompt sheet: "Get notified when it's time? Daymark will alert you and you can mark it done right from the notification." Buttons: [Allow notifications] [Not now].
   - [Allow] calls the OS prompt (Android `requestNotificationsPermission()`, iOS `requestPermissions(alert:true, badge:true, sound:true)`).
   - Save the reminder either way. It still shows in the app; it just won't alert.
2. **Exact alarms (Android only).** After notifications are granted, if `canScheduleExactNotifications() == false`, show: "For on-time alerts, allow Daymark to set alarms." [Open settings] calls `requestExactAlarmsPermission()`, then re-check on app resume. If declined, keep using inexact mode and show a small "may arrive a few minutes late" note in Settings.
3. **Settings row.** Profile → Notifications (`build_profile_widget.dart` ~1544 "Notifications" sheet): show the status ("On", "Off – tap to enable", "On, but may be late"). If permanently denied, the button opens the OS app settings (`app_settings`, or a platform channel). Hide the row when `NotificationService.isSupported == false`.
4. **Banner.** On the Workspace screen, if the user has ≥1 pending future reminder and notifications are off, show a dismissible banner: "Reminders won't alert you — Turn on notifications."
5. Re-check permission on every app resume (`AppLifecycleListener`). If it changed to granted, call `ReminderScheduler.reconcile()` (REM-03).

## Implementation
- Add `NotificationPermissionService` (or methods on `NotificationService`): `status()` → enum `{granted, denied, permanentlyDenied, notDetermined, unsupported}`, `request()`, `canScheduleExact()`, `requestExact()`, `openSettings()`.
  - Android: `areNotificationsEnabled()`, `requestNotificationsPermission()`, `canScheduleExactNotifications()`, `requestExactAlarmsPermission()`.
  - iOS/macOS: `checkPermissions()` (returns `NotificationsEnabledOptions` in newer plugin versions) and `requestPermissions(...)`.
- Save "pre-prompt already shown" in `Preference` so the user isn't nagged. Show it again at most once per 30 days.

## Acceptance criteria
- [ ] Fresh install on Android 14: the first reminder save shows the pre-prompt, then the OS prompt. Granting it makes the reminder fire on time once exact alarms are allowed.
- [ ] Denying it doesn't block saving. The banner and settings row reflect the state, and "Open settings" works.
- [ ] iOS: the same flow. After a permanent denial, the settings deep link works.
- [ ] Widget tests for the pre-prompt logic with a fake permission service.
