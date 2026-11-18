import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/screens/splash/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
    await Preference.init();
  });

  testWidgets('Daymark Splash screen renders brand text and logo',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(412, 892),
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SplashScreen(),
          ),
        ),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify brand text elements from Figma design
    expect(find.text('Daymark'), findsOneWidget);
    expect(find.text('Thoughtful daily notes'), findsOneWidget);
    expect(find.text('A CALM SPACE FOR YOUR THOUGHTS'), findsOneWidget);
    expect(find.text('DAYMARK · VERSION 1.0.0'), findsOneWidget);
  });
}
