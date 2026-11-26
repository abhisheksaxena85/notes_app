import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/internet_connection_service.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/screens/splash/splash_screen.dart';

import 'package:notes_app/data/di/dependency_injection.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool isInternetConnected = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialize();
  runApp(const ProviderScope(child: MyApp()));
}

/// Starting important required services
Future<void> initialize() async {
  await configureDependencies();

  await Preference.init();

  getIt<SessionService>().restore();
  // Sync queued changes when the app returns to the foreground too, not only
  // when connectivity changes. The listener registers itself with the binding
  // and lives as long as the app.
  AppLifecycleListener(onResume: getIt<OfflineSyncService>().onAppResumed);
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(412, 892),
      builder: (context, child) {
        return MaterialApp(
          builder: (context, child) {
            internetStatusListener(context);
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
          title: 'Daymark',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
