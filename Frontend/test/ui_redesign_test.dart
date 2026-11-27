import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/widgets/daymark_bottom_nav.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/reminder_answer_sheet.dart';
import 'package:notes_app/views/widgets/skeleton/skeleton.dart';

/// UI-10: the v2 redesign's shared widgets (design/README.md).
void main() {
  Widget host(Widget child, {bool disableAnimations = false, ThemeMode mode = ThemeMode.light}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  const skeleton = Shimmer(
    child: Column(
      children: [
        SkeletonBox(width: 120, height: 14),
        SkeletonLine(widthFactor: 0.5),
        SkeletonCircle(size: 44),
      ],
    ),
  );

  group('Skeleton', () {
    testWidgets('shimmers with one shared controller and announces loading',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(skeleton));
      await tester.pump(const Duration(milliseconds: 300));

      // Every block paints the shared gradient.
      expect(find.byType(ShaderMask), findsNWidgets(3));
      expect(tester.hasRunningAnimations, isTrue);
      expect(Shimmer.period, const Duration(milliseconds: 1400));
      expect(find.bySemanticsLabel('Loading…'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('is static skeletonBase when animations are disabled',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(skeleton, disableAnimations: true));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      final boxes = tester
          .widgetList<Container>(find.descendant(
            of: find.byType(SkeletonBox),
            matching: find.byType(Container),
          ))
          .map((c) => (c.decoration as BoxDecoration).color);
      expect(boxes, everyElement(DaymarkPalette.light.skeletonBase));
      expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('uses the dark skeleton colour in dark mode', (tester) async {
      await tester.pumpWidget(host(skeleton, disableAnimations: true, mode: ThemeMode.dark));
      final colors = tester
          .widgetList<Container>(find.descendant(
            of: find.byType(SkeletonBox),
            matching: find.byType(Container),
          ))
          .map((c) => (c.decoration as BoxDecoration).color);
      expect(colors, everyElement(DaymarkPalette.dark.skeletonBase));
    });
  });

  group('Bottom nav', () {
    const items = [
      DaymarkNavItem(icon: AppIcons.workspace, label: 'Workspace'),
      DaymarkNavItem(icon: AppIcons.calendar, label: 'Calendar'),
      DaymarkNavItem(icon: AppIcons.profile, label: 'Profile'),
    ];

    testWidgets('the active item has the accentSoft pill and accent label at 600',
        (tester) async {
      var current = 1;
      await tester.pumpWidget(host(StatefulBuilder(
        builder: (context, setState) => Align(
          alignment: Alignment.bottomCenter,
          child: DaymarkBottomNav(
            items: items,
            currentIndex: current,
            onTap: (i) => setState(() => current = i),
          ),
        ),
      )));
      await tester.pumpAndSettle();
      final palette = DaymarkPalette.light;

      Text label(String text) => tester.widget<Text>(find.text(text));
      BoxDecoration pill(String text) => tester
          .widget<AnimatedContainer>(find.descendant(
            of: find.widgetWithText(DaymarkNavButton, text),
            matching: find.byType(AnimatedContainer),
          ))
          .decoration! as BoxDecoration;

      expect(label('Calendar').style?.color, palette.accent);
      expect(label('Calendar').style?.fontWeight, FontWeight.w600);
      expect(pill('Calendar').color, palette.accentSoft);
      expect(label('Workspace').style?.color, palette.muted);
      expect(label('Workspace').style?.fontWeight, FontWeight.w500);
      expect(pill('Workspace').color, Colors.transparent);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(current, 2);
      expect(label('Profile').style?.color, palette.accent);
      expect(pill('Profile').color, palette.accentSoft);
      expect(label('Calendar').style?.color, palette.muted);
    });
  });

  group('Primary button', () {
    testWidgets('uses the disabled colours without an action', (tester) async {
      await tester.pumpWidget(host(const PrimaryButton(label: 'Save note', onPressed: null)));
      final text = tester.widget<Text>(find.text('Save note'));
      expect(text.style?.color, DaymarkPalette.light.onButtonDisabled);
      final material = tester.widget<Material>(find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(Material),
      ));
      expect(material.color, DaymarkPalette.light.buttonDisabled);
    });
  });

  group('Formatting', () {
    test('"Did you {title}?" keeps names and acronyms', () {
      expect(reminderQuestion('Take pills'), 'Did you take pills?');
      expect(reminderQuestion('NASA call'), 'Did you NASA call?');
      expect(reminderQuestion('  '), 'Did you complete it?');
    });

    test('greeting follows the time of day', () {
      expect(DisplayFormat.greeting(DateTime(2026, 11, 27, 8)), 'Good morning');
      expect(DisplayFormat.greeting(DateTime(2026, 11, 27, 13)), 'Good afternoon');
      expect(DisplayFormat.greeting(DateTime(2026, 11, 27, 19)), 'Good evening');
    });

    test('due dates and relative times', () {
      final now = DateTime(2026, 11, 27, 9);
      expect(DisplayFormat.longDate(now), 'Friday, 27 November');
      expect(DisplayFormat.due('2026-11-27', '10:30', now), '10:30 AM');
      expect(DisplayFormat.due('2026-11-28', '18:00', now), 'Tomorrow, 6:00 PM');
      expect(DisplayFormat.due('2026-11-24', null, now), '24 Nov');
      expect(DisplayFormat.relative(now.subtract(const Duration(hours: 2)), now), '2h ago');
      expect(DisplayFormat.relative(DateTime(2026, 11, 26, 20), now), 'Yesterday');
      expect(DisplayFormat.initials('Ada Lovelace'), 'AL');
    });
  });
}
