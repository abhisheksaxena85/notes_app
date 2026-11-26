import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/widgets/notification_permission_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_notification_platform.dart';

/// REM-02: notification permission asked in context, with a fake OS.
void main() {
  late FakeNotificationPlatform platform;

  NotificationPermissionService service({
    bool supported = true,
    bool android = true,
  }) => NotificationPermissionService(
    notifications: NotificationService(platform: platform, supported: supported, android: android),
    preference: Preference(),
    permissionIsFinal: !android,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Preference.init();
    platform = FakeNotificationPlatform()
      ..enabled = false
      ..exact = true;
    NotificationsOffBanner.resetDismissed();
  });

  group('status', () {
    test('never asked is notDetermined, then denied on Android', () async {
      final permissions = service();
      expect((await permissions.refresh()).permission, NotificationPermission.notDetermined);

      platform.grantOnRequest = false;
      expect(await permissions.request(), isFalse);
      expect(permissions.status.value.permission, NotificationPermission.denied);
      expect(permissions.status.value.alertsOff, isTrue);
    });

    test('a refusal on iOS is permanent', () async {
      final permissions = service(android: false);
      platform.grantOnRequest = false;
      await permissions.request();
      expect(permissions.status.value.permission, NotificationPermission.permanentlyDenied);
    });

    test('granted without exact alarms may be late', () async {
      platform
        ..enabled = true
        ..exact = false;
      final status = await service().refresh();
      expect(status.permission, NotificationPermission.granted);
      expect(status.mayBeLate, isTrue);
      expect(notificationStatusLabel(status), 'On, but may be late');
    });

    test('unsupported platforms report unsupported and never call the OS', () async {
      final permissions = service(supported: false);
      expect((await permissions.refresh()).permission, NotificationPermission.unsupported);
      expect(await permissions.request(), isFalse);
      expect(await permissions.shouldShowPrePrompt(), isFalse);
      expect(platform.permissionRequests, 0);
    });
  });

  group('pre-prompt throttling', () {
    test('shown while undecided, at most once per 30 days', () async {
      final permissions = service();
      final day0 = DateTime(2026, 11, 1);
      expect(await permissions.shouldShowPrePrompt(now: day0), isTrue);
      await permissions.markPrePromptShown(now: day0);
      expect(await permissions.shouldShowPrePrompt(now: day0.add(const Duration(days: 29))), isFalse);
      expect(await permissions.shouldShowPrePrompt(now: day0.add(const Duration(days: 30))), isTrue);
    });

    test('never shown once the OS has been asked or it is granted', () async {
      final permissions = service();
      platform.grantOnRequest = false;
      await permissions.request();
      expect(await permissions.shouldShowPrePrompt(), isFalse);

      platform.enabled = true;
      expect(await permissions.shouldShowPrePrompt(), isFalse);
    });
  });

  group('enable (settings row and banner)', () {
    test('asks when undecided and opens settings if still off', () async {
      platform.grantOnRequest = false;
      await service().enable();
      expect(platform.permissionRequests, 1);
      expect(platform.settingsOpened, 1);
    });

    test('opens settings straight away when refused for good', () async {
      final permissions = service(android: false);
      platform.grantOnRequest = false;
      await permissions.request();
      await permissions.enable();
      expect(platform.permissionRequests, 1);
      expect(platform.settingsOpened, 1);
    });

    test('asks for exact alarms when only those are missing', () async {
      platform
        ..enabled = true
        ..exact = false;
      await service().enable();
      expect(platform.exactRequests, 1);
      expect(platform.permissionRequests, 0);
    });
  });

  Widget host(Widget Function(BuildContext) child) => ScreenUtilInit(
    designSize: const Size(412, 892),
    builder: (context, _) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Builder(builder: child)),
    ),
  );

  Future<void> openFlow(WidgetTester tester, NotificationPermissionService permissions) async {
    await tester.pumpWidget(host((context) => TextButton(
      onPressed: () => maybeAskForNotifications(context, permissions),
      child: const Text('save'),
    )));
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
  }

  group('pre-prompt flow', () {
    testWidgets('Allow shows the OS prompt, then the exact-alarm explainer', (tester) async {
      platform
        ..grantOnRequest = true
        ..exact = false;
      final permissions = service();
      await openFlow(tester, permissions);

      expect(find.text("Get notified when it's time?"), findsOneWidget);
      await tester.tap(find.text('Allow notifications'));
      await tester.pumpAndSettle();
      expect(platform.permissionRequests, 1);

      expect(find.textContaining('allow Daymark to set alarms'), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(platform.exactRequests, 1);
    });

    testWidgets('no exact-alarm explainer when exact alarms are allowed', (tester) async {
      platform.grantOnRequest = true;
      await openFlow(tester, service());
      await tester.tap(find.text('Allow notifications'));
      await tester.pumpAndSettle();
      expect(find.textContaining('allow Daymark to set alarms'), findsNothing);
    });

    testWidgets('Not now skips the OS prompt and is not asked again soon', (tester) async {
      final permissions = service();
      await openFlow(tester, permissions);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(platform.permissionRequests, 0);

      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();
      expect(find.text("Get notified when it's time?"), findsNothing);
    });

    testWidgets('nothing is shown when notifications are already on', (tester) async {
      platform.enabled = true;
      await openFlow(tester, service());
      expect(find.text("Get notified when it's time?"), findsNothing);
    });
  });

  group('Workspace banner', () {
    Future<void> pumpBanner(WidgetTester tester, NotificationPermissionService permissions,
        {bool upcoming = true}) async {
      await permissions.refresh();
      await tester.pumpWidget(host((_) => NotificationsOffBanner(
        permissions: permissions,
        hasUpcomingReminders: upcoming,
      )));
    }

    testWidgets('shown with upcoming reminders while notifications are off', (tester) async {
      await pumpBanner(tester, service());
      expect(find.textContaining("Reminders won't alert you"), findsOneWidget);

      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pump();
      expect(find.textContaining("Reminders won't alert you"), findsNothing);
    });

    testWidgets('hidden without upcoming reminders, when on, or unsupported', (tester) async {
      await pumpBanner(tester, service(), upcoming: false);
      expect(find.textContaining("Reminders won't alert you"), findsNothing);

      platform.enabled = true;
      await pumpBanner(tester, service());
      expect(find.textContaining("Reminders won't alert you"), findsNothing);

      platform.enabled = false;
      await pumpBanner(tester, service(supported: false));
      expect(find.textContaining("Reminders won't alert you"), findsNothing);
    });

    testWidgets('tapping it asks for permission', (tester) async {
      platform.grantOnRequest = true;
      final permissions = service();
      await pumpBanner(tester, permissions);
      await tester.tap(find.textContaining('Turn on notifications', findRichText: true));
      await tester.pumpAndSettle();
      expect(platform.permissionRequests, 1);
      expect(find.textContaining("Reminders won't alert you"), findsNothing);
    });
  });
}
