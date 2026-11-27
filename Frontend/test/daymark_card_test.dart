import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/screens/home/widgets/task_item_card.dart';
import 'package:notes_app/views/screens/home/widgets/workspace_header.dart';
import 'package:notes_app/views/widgets/daymark_card.dart';

/// FIX-03: the shared card has a softer 0.5 px border, a soft shadow, more
/// room, and stays cheap in long lists.
void main() {
  Widget host(Widget child, {ThemeMode mode = ThemeMode.light}) => MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        home: Scaffold(body: Padding(padding: const EdgeInsets.all(20), child: child)),
      );

  BoxDecoration decorationOf(WidgetTester tester, Finder card) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: card, matching: find.byType(DecoratedBox)).first,
    );
    return box.decoration as BoxDecoration;
  }

  testWidgets('light: 0.5 px #E9E9E5 border, two soft ink shadows, radius 18, padding 16',
      (tester) async {
    await tester.pumpWidget(host(const DaymarkCard(child: Text('Card'))));
    final card = find.byType(DaymarkCard);
    final decoration = decorationOf(tester, card);

    final side = (decoration.border! as Border).top;
    expect(side.width, 0.5);
    expect(side.color, const Color(0xFFE9E9E5));
    expect(decoration.color, DaymarkPalette.light.surface);
    expect(decoration.borderRadius, const BorderRadius.all(Radius.circular(18)));
    expect(decoration.boxShadow, const [
      BoxShadow(color: Color(0x0D2A2B2F), blurRadius: 14, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x082A2B2F), blurRadius: 3, offset: Offset(0, 1)),
    ]);
    final shadowInk = decoration.boxShadow!.first.color;
    expect(shadowInk.withValues(alpha: 1), DaymarkPalette.light.ink, reason: 'the shadow is ink');
    expect(tester.getTopLeft(find.text('Card')) - tester.getTopLeft(card), const Offset(16, 16));
  });

  testWidgets('dark: #33353A hairline and one black 28 % shadow', (tester) async {
    await tester.pumpWidget(host(const DaymarkCard(child: Text('Card')), mode: ThemeMode.dark));
    final decoration = decorationOf(tester, find.byType(DaymarkCard));

    final side = (decoration.border! as Border).top;
    expect(side.width, 0.5);
    expect(side.color, const Color(0xFF33353A));
    expect(decoration.color, DaymarkPalette.dark.surface);
    expect(decoration.boxShadow, const [
      BoxShadow(color: Color(0x47000000), blurRadius: 16, offset: Offset(0, 6)),
    ]);
  });

  test('the card border token matches the card', () {
    expect(DaymarkPalette.light.cardBorder, const Color(0xFFE9E9E5));
    expect(DaymarkPalette.dark.cardBorder, const Color(0xFF33353A));
  });

  test('one const decoration per theme and radius (no per-build allocation)', () {
    for (final palette in [DaymarkPalette.light, DaymarkPalette.dark]) {
      expect(identical(DaymarkCard.decorationFor(palette), DaymarkCard.decorationFor(palette)), isTrue);
      expect(
        identical(
          DaymarkCard.decorationFor(palette, radius: DaymarkCard.largeRadius),
          DaymarkCard.decorationFor(palette, radius: DaymarkCard.largeRadius),
        ),
        isTrue,
      );
    }
    expect(DaymarkCard.decorationFor(DaymarkPalette.light, radius: 22).borderRadius,
        const BorderRadius.all(Radius.circular(22)));
  });

  testWidgets('item cards add no clip layer; only grouped cards opt in', (tester) async {
    await tester.pumpWidget(host(Column(
      children: [
        DaymarkCard(onTap: () {}, child: const Text('Tappable')),
        const DaymarkCard(child: Text('Plain')),
      ],
    )));
    expect(find.byType(ClipRRect), findsNothing);
    for (final material in tester.widgetList<Material>(
      find.descendant(of: find.byType(DaymarkCard), matching: find.byType(Material)),
    )) {
      expect(material.clipBehavior, Clip.none);
      expect(material.type, MaterialType.transparency);
    }
    expect(find.descendant(of: find.byType(DaymarkCard), matching: find.byType(DecoratedBox)),
        findsNWidgets(2), reason: 'one DecoratedBox per card');

    await tester.pumpWidget(host(const DaymarkCard(clipContent: true, child: Text('Group'))));
    final material = tester.widget<Material>(
      find.descendant(of: find.byType(DaymarkCard), matching: find.byType(Material)),
    );
    expect(material.clipBehavior, Clip.antiAlias);
  });

  testWidgets('task card: 24 px checkbox, 16 inset, 6 between title and meta, 10 between cards',
      (tester) async {
    final task = TaskItem(taskId: 1, title: 'Write report', category: 'Work', priority: 'HIGH');
    await tester.pumpWidget(host(Builder(
      builder: (context) => Column(
        children: [
          taskItemCard(context: context, task: task, onToggleComplete: (_) {}, onTap: () {}),
          taskItemCard(context: context, task: task, onToggleComplete: (_) {}, onTap: () {}),
        ],
      ),
    )));

    final cards = find.byType(DaymarkCard);
    final first = tester.getRect(cards.at(0));
    final second = tester.getRect(cards.at(1));
    expect(second.top - first.bottom, DaymarkCard.gap);
    expect(DaymarkCard.gap, 10);

    final checkbox = find.descendant(
      of: cards.at(0),
      matching: find.byWidgetPredicate(
        (w) => w is AnimatedContainer && w.constraints?.maxWidth == 24,
      ),
    );
    expect(tester.getSize(checkbox), const Size(24, 24));
    expect(tester.getTopLeft(checkbox).dx - first.left, 16);

    final title = tester.getRect(find.text('Write report').first);
    expect(title.top - first.top, 16);
    final meta = tester.getRect(find.textContaining('Work').first);
    expect(meta.top - title.bottom, 6);
  });

  testWidgets('stat cards use the shared card and sit 10 apart', (tester) async {
    await tester.pumpWidget(host(const WorkspaceStats(tasksToday: 1, reminders: 2, notes: 3)));
    final cards = find.byType(DaymarkCard);
    expect(cards, findsNWidgets(3));
    expect(tester.getRect(cards.at(1)).left - tester.getRect(cards.at(0)).right, 10);
  });
}
