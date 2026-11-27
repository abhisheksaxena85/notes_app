import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/connectivity_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:notes_app/utils/services/digest_scheduler.dart';
import 'package:notes_app/utils/services/home_widgets/widget_actions.dart';
import 'package:notes_app/utils/services/home_widgets/widget_host.dart';
import 'package:notes_app/utils/services/home_widgets/widget_inbox.dart';
import 'package:notes_app/utils/services/home_widgets/widget_links.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot_service.dart';
import 'package:notes_app/utils/services/notification_background.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';
import 'package:notes_app/utils/services/reminder_scheduler.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/auth/login/login_screen.dart';
import 'package:notes_app/views/screens/quick_add/quick_add_task_app.dart';
import 'package:notes_app/views/screens/splash/splash_screen.dart';
import 'package:notes_app/views/widgets/connectivity_snackbar_listener.dart';
import 'package:notes_app/views/widgets/reminder_answer_sheet.dart';

import 'package:notes_app/data/di/dependency_injection.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// App-wide snackbars that don't belong to one screen (connectivity).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// W-03 (Android): the Dart entrypoint of QuickAddTaskActivity, the
/// quick-add pop-up the Tasks widget's plus opens over the home screen.
@pragma('vm:entry-point')
void quickAddTaskMain() => runQuickAddTaskApp();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialize();
  runApp(const ProviderScope(child: MyApp()));
}

/// Starting important required services
Future<void> initialize() async {
  await configureDependencies();

  await Preference.init();

  // REM-01: time zones, channels and the notification callbacks. Never
  // blocks startup: without notifications the app still works.
  final notifications = getIt<NotificationService>();
  void onResponse(NotificationResponse response) => routeNotificationResponse(
    response,
    handler: () => getIt<ReminderActionHandler>(),
    messenger: scaffoldMessengerKey,
  );
  try {
    await notifications.init(
      onForegroundResponse: onResponse,
      onBackgroundResponse: notificationTapBackground,
    );
    // REM-04: the app was started by tapping a notification (cold start).
    final launch = await notifications.launchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && response != null) onResponse(response);
  } catch (error, stackTrace) {
    log('Notifications are unavailable: $error', stackTrace: stackTrace);
  }
  final permissions = getIt<NotificationPermissionService>();
  unawaited(permissions.refresh());

  // The app's only connectivity checker. The sync service and the
  // connectivity snackbars subscribe to it.
  getIt<ConnectivityService>().start();
  final session = getIt<SessionService>()..restore();
  // SEC-02: the server rejected the session (401). SessionService has signed
  // out once; show the login screen.
  session.expirations.listen((_) => _showLoginAfterExpiry());
  // REM-03: scheduled notifications follow the signed-in user's reminders.
  final scheduler = getIt<ReminderScheduler>()
    ..start(userChanges: session.changes, permission: permissions.status);
  unawaited(scheduler.reconcile());
  // REM-08: digests that are on but missing, and fresh weekly counts.
  final digests = getIt<DigestScheduler>();
  unawaited(digests.reconcile());
  // W-01: home-screen widgets follow the signed-in user's tasks and reminders.
  final widgets = getIt<WidgetSnapshotService>()
    ..start(
      userChanges: session.changes,
      syncCompletions: getIt<OfflineSyncService>().completions,
    );
  // W-03 / W-06: tasks added through the iOS App Intent and widget taps iOS
  // queued while the app was closed.
  final inbox = getIt<WidgetTaskInbox>();
  Future<void> catchUpWidgets() async {
    await getIt<WidgetPendingActions>().applyAll(getIt<WidgetActionHandler>());
    await inbox.importAll();
  }

  unawaited(catchUpWidgets());
  session.changes.listen((userId) {
    if (userId != 0) unawaited(catchUpWidgets());
  });
  unawaited(_listenForWidgetLaunches());
  // Sync queued changes when the app returns to the foreground too, not only
  // when connectivity changes. The listener registers itself with the binding
  // and lives as long as the app.
  AppLifecycleListener(
    onResume: () {
      getIt<OfflineSyncService>().onAppResumed();
      // REM-02: the user may have changed the permission in the OS settings.
      unawaited(permissions.refresh());
      // REM-03: time zone changes and occurrences missed while closed.
      unawaited(scheduler.onAppResumed());
      unawaited(digests.reconcile());
      unawaited(catchUpWidgets().then((_) => widgets.onAppResumed()));
    },
  );
}

/// A widget tap that opened the app: a screen to show, or (iOS 15/16, where
/// widget buttons can only open the app) an action to apply first.
void _onWidgetLaunch(Uri? uri) {
  if (WidgetAction.parse(uri) == null) {
    routeWidgetLaunch(uri);
    return;
  }
  unawaited(() async {
    await getIt<WidgetActionHandler>().handle(uri);
    await getIt<WidgetPendingActions>().remove(uri);
  }());
  routeWidgetLaunch(Uri.parse('daymark://workspace'));
}

/// W-01: widget taps that opened the app (cold start) or brought it to the
/// front (warm start) go to the dashboard, which opens the right screen.
Future<void> _listenForWidgetLaunches() async {
  if (!HomeWidgetHost().isSupported) return;
  try {
    await HomeWidget.setAppGroupId(DaymarkWidgets.appGroupId);
    // W-02: ticking a task or answering a reminder on a widget.
    await HomeWidget.registerInteractivityCallback(widgetInteractivityCallback);
    HomeWidget.widgetClicked.listen(
      _onWidgetLaunch,
      onError: (Object error) => log('Widget click failed: $error'),
    );
    _onWidgetLaunch(await HomeWidget.initiallyLaunchedFromHomeWidget());
  } catch (error, stackTrace) {
    log('Widget launches are unavailable: $error', stackTrace: stackTrace);
  }
}

/// After a 401: drop the signed-out user's screens and state, then show the
/// login screen with one message.
void _showLoginAfterExpiry() {
  final context = navigatorKey.currentContext;
  if (context == null) return;
  final container = ProviderScope.containerOf(context, listen: false);
  for (final controller in sessionScopedControllers) {
    container.invalidate(controller);
  }
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (route) => false,
  );
  scaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(failedSnackBar('Your session has expired. Please log in again.'));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(412, 892),
      builder: (context, child) {
        return ConnectivitySnackbarListener(
          connectivity: getIt<ConnectivityService>(),
          messengerKey: scaffoldMessengerKey,
          child: MaterialApp(
            builder: (context, child) {
              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    return false;
                  },
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: scaffoldMessengerKey,
            title: 'Daymark',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
