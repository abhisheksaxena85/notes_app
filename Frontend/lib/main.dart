import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/utils/services/internet_connection_service.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/screens/auth/login/login_screen.dart';

import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/views/screens/dashboard/dashboard_screen.dart';
import 'package:notes_app/views/screens/home/home_screen.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool isInternetConnected = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialize();
  runApp(ProviderScope(child: MyApp()));
}

/// Starting important required services
Future<void> initialize() async {
  await configureDependencies();

  await Preference.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          title: 'Notes',
          theme: AppTheme.defaultAppTheme(),
          home: DashboardScreen(),
        );
      },
    );
  }
}
