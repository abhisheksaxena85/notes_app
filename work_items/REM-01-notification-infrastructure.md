# REM-01 — Add the notification plugin, platform setup and `NotificationService`

**Type:** Feature · **Priority:** P1 · **Area:** Frontend (Android/iOS/macOS native config) · **Depends on:** none · **Read:** REM-00

## Scope
Set up the plumbing so the app can show and schedule a local notification with action buttons on Android and iOS. No reminder logic yet. That's REM-03 and REM-04.

## Tasks
### 1. Dependencies (`Frontend/pubspec.yaml`)
Add `flutter_local_notifications`, `timezone` and `flutter_timezone` (latest stable versions compatible with the project's Flutter SDK). Run `flutter pub get`.

### 2. Android
- `android/app/build.gradle.kts`:
  - `compileOptions { isCoreLibraryDesugaringEnabled = true }` (keep Java 17)
  - `defaultConfig { multiDexEnabled = true }`
  - `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }` (or the version the plugin README asks for)
  - Make sure `compileSdk` ≥ 35 (check `flutter.compileSdkVersion`; set it explicitly if lower) and that AGP in `android/settings.gradle.kts` meets the plugin's minimum.
- `android/app/src/main/AndroidManifest.xml`:
  - permissions: `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` (POST_NOTIFICATIONS and VIBRATE come from the plugin). Don't add `USE_EXACT_ALARM` unless the owner accepts the Play policy review.
  - inside `<application>` (all `android:exported="false"`):
    ```xml
    <receiver android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" android:exported="false"/>
    <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" android:exported="false"/>
    <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" android:exported="false">
      <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
      </intent-filter>
    </receiver>
    ```
- Add a monochrome notification icon `android/app/src/main/res/drawable/ic_stat_daymark.png` (white on transparent; can be generated from `assets/icons/bell.svg`). Use it as the default icon. Without one, Android shows a white square.
- If release builds use R8/minify later, keep the plugin's Gson classes (see the plugin README's proguard notes).

### 3. iOS (`ios/Runner/AppDelegate.swift`)
The project uses the **UIScene / implicit engine** lifecycle (`FlutterImplicitEngineDelegate`). Put the setup in `didInitializeImplicitFlutterEngine`:
```swift
import flutter_local_notifications
…
func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
  GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
    GeneratedPluginRegistrant.register(with: registry)
  }
  UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
}
```
(Check the exact API against the plugin's README for the installed version.) No Info.plist keys are needed for local notifications.

### 4. macOS (optional)
The same `UNUserNotificationCenter` delegate setup in `macos/Runner/AppDelegate.swift`, and `MACOSX_DEPLOYMENT_TARGET` ≥ 10.14 (it's already 12.0). If this isn't worth it, make the service a no-op on macOS.

### 5. `lib/utils/services/notification_service.dart` (new, registered in get_it)
- `bool get isSupported`: Android, iOS (and macOS) only. `kIsWeb` → false.
- `Future<void> init({required void Function(NotificationResponse) onForegroundResponse})`:
  - `tz.initializeTimeZones()`; `tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()))`, wrapped in try/catch with a fallback to UTC. (The return type differs between `flutter_timezone` versions; check it.)
  - Android channel **`reminders`**: name "Reminders", importance high, sound and vibration on, `AndroidNotificationCategory.reminder`.
  - Android channel **`digests`**: name "Daily & weekly summaries", default importance (used by REM-08).
  - Darwin init: `requestAlertPermission/requestBadgePermission/requestSoundPermission: false` (REM-02 asks at the right moment), plus `notificationCategories: [DarwinNotificationCategory('daymark_reminder', actions: [plain('reminder_done','Done'), plain('reminder_not_done','Not done', options:{destructive}), plain('reminder_snooze','Snooze 10 min')])]`.
  - `initialize(…, onDidReceiveNotificationResponse: onForegroundResponse, onDidReceiveBackgroundNotificationResponse: notificationTapBackground)`.
- `Future<NotificationAppLaunchDetails?> launchDetails()`, a wrapper around `getNotificationAppLaunchDetails()` for cold start (REM-04).
- `Future<void> schedule({required int id, required tz.TZDateTime at, required String title, required String body, required String payload, String channel = 'reminders', bool withActions = true})`:
  - Android details: channel, `actions: [AndroidNotificationAction('reminder_done','Done', showsUserInterface:false, cancelNotification:true), …not_done…, …snooze…]`, `category: reminder`, `icon: 'ic_stat_daymark'`, `when` set to the occurrence time.
  - Darwin details: `categoryIdentifier: 'daymark_reminder'`, `interruptionLevel: timeSensitive` (only if the entitlement is added; otherwise `active`).
  - `androidScheduleMode`: `exactAllowWhileIdle` when `canScheduleExactNotifications()` is true, else `inexactAllowWhileIdle`.
- `cancel(int id)`, `cancelAll()`, `Future<List<PendingNotificationRequest>> pending()`.
- `showNow(...)` for a debug "Test notification" button (debug builds only, under Profile → Notifications).
- Top-level, **outside any class**:
  ```dart
  @pragma('vm:entry-point')
  void notificationTapBackground(NotificationResponse response) {
    // REM-04 fills this in: ensure bindings/plugins, open DB, call ReminderActionHandler.
  }
  ```
### 6. Wire into startup
In `main.dart` `initialize()`, after `configureDependencies()` and `Preference.init()`: `await getIt<NotificationService>().init(onForegroundResponse: …)`. For now, log the response; REM-04 replaces this.

## Acceptance criteria
- [ ] `flutter build apk --debug` and `flutter build ios --no-codesign` succeed.
- [ ] The debug "Test notification" shows a notification with three action buttons on an Android 14 emulator and an iOS 17+ simulator/device (after granting permission manually or via REM-02).
- [ ] A notification scheduled 1 minute ahead fires with the app **killed** (Android) or in the background (iOS).
- [ ] On web/desktop the app runs and `isSupported == false`.
- [ ] Unit test: `NotificationService` builds the right `AndroidNotificationDetails`/actions (inject the plugin behind a small interface so it can be faked).
