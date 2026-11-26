import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/connectivity_service.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/screens/splash/splash_screen.dart';
import 'package:notes_app/views/widgets/connectivity_snackbar_listener.dart';

import 'package:notes_app/data/di/dependency_injection.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// App-wide snackbars that don't belong to one screen (connectivity).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
  try {
    await getIt<NotificationService>().init(
      onForegroundResponse: (response) =>
          log('Notification response ${response.actionId} (app running)'),
      onBackgroundResponse: notificationTapBackground,
    );
  } catch (error, stackTrace) {
    log('Notifications are unavailable: $error', stackTrace: stackTrace);
  }
  final permissions = getIt<NotificationPermissionService>();
  unawaited(permissions.refresh());

  // The app's only connectivity checker. The sync service and the
  // connectivity snackbars subscribe to it.
  getIt<ConnectivityService>().start();
  getIt<SessionService>().restore();
  // Sync queued changes when the app returns to the foreground too, not only
  // when connectivity changes. The listener registers itself with the binding
  // and lives as long as the app.
  AppLifecycleListener(
    onResume: () {
      getIt<OfflineSyncService>().onAppResumed();
      // REM-02: the user may have changed the permission in the OS settings.
      unawaited(permissions.refresh());
    },
  );
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
