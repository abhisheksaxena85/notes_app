import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/home_widgets/widget_inbox.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/widgets/quick_add_task_sheet.dart';

import 'support/fake_server.dart';
import 'support/fake_widget_host.dart';

/// W-03: the quick-add sheet and the iOS widget task inbox.
void main() {
  group('QuickAddTaskSheet', () {
    late List<QuickAddTaskDraft> saved;
    var done = 0;

    Future<void> pump(WidgetTester tester, {Future<void> Function(QuickAddTaskDraft)? onSave}) async {
      saved = [];
      done = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: QuickAddTaskSheet(
              onSave: onSave ?? (draft) async => saved.add(draft),
              onDone: () => done++,
            ),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('focuses the title, defaults to Today, and adds the task', (tester) async {
      await pump(tester);

      final field = tester.widget<TextField>(find.byKey(const Key('quickAddTitle')));
      expect(field.autofocus, isTrue);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('No date'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('quickAddTitle')), '  Water the plants ');
      await tester.pump();
      await tester.tap(find.text('Add task'));
      await tester.pump();
      await tester.pump();

      expect(saved, hasLength(1));
      expect(saved.single.title, '  Water the plants ');
      expect(saved.single.due, QuickAddDue.today);
      expect(saved.single.time, isNull);
      expect(done, 1);
    });

    testWidgets('"Add task" is disabled until there is a title', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Add task'));
      await tester.enterText(find.byKey(const Key('quickAddTitle')), '   ');
      await tester.pump();
      await tester.tap(find.text('Add task'));
      await tester.pump();

      expect(saved, isEmpty);
      expect(done, 0);
    });

    testWidgets('Tomorrow and No date; no time picker without a date', (tester) async {
      await pump(tester);
      expect(find.text('Add a time (optional)'), findsOneWidget);

      await tester.tap(find.text('No date'));
      await tester.pump();
      expect(find.text('Add a time (optional)'), findsNothing);

      await tester.tap(find.text('Tomorrow'));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('quickAddTitle')), 'Dentist');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump();

      expect(saved.single.due, QuickAddDue.tomorrow);
    });

    testWidgets('a failed save keeps the sheet open with the error', (tester) async {
      await pump(tester, onSave: (_) async => throw StateError('disk full'));

      await tester.enterText(find.byKey(const Key('quickAddTitle')), 'Oops');
      await tester.pump();
      await tester.tap(find.text('Add task'));
      await tester.pump();
      await tester.pump();

      expect(done, 0);
      expect(find.byKey(const Key('quickAddTitle')), findsOneWidget);
    });
  });

  group('QuickAddTaskDraft.toRequest', () {
    final now = DateTime(2026, 12, 31, 22, 15);

    test('today, tomorrow (across the year), no date', () {
      expect(const QuickAddTaskDraft(title: ' A ').toRequest(5, now).dueDate, '2026-12-31');
      expect(const QuickAddTaskDraft(title: 'A').toRequest(5, now).title, 'A');
      expect(
        const QuickAddTaskDraft(title: 'A', due: QuickAddDue.tomorrow).toRequest(5, now).dueDate,
        '2027-01-01',
      );
      final undated = const QuickAddTaskDraft(
        title: 'A',
        due: QuickAddDue.none,
        time: TimeOfDay(hour: 9, minute: 0),
      ).toRequest(5, now);
      expect(undated.dueDate, isNull);
      expect(undated.dueTime, isNull);
    });

    test('a time is sent as HH:mm', () {
      final request = const QuickAddTaskDraft(title: 'A', time: TimeOfDay(hour: 7, minute: 5))
          .toRequest(5, now);
      expect(request.dueTime, '07:05');
      expect(request.userId, 5);
    });
  });

  group('saveQuickAddTask and the inbox', () {
    const userId = 9;
    late AppDatabase database;
    late OfflineSyncService sync;
    late TaskRepo repo;
    late FakeWidgetHost host;
    late WidgetTaskInbox inbox;
    var signedIn = userId;

    setUp(() {
      signedIn = userId;
      database = AppDatabase.forTesting(NativeDatabase.memory());
      final server = FakeServer();
      sync = OfflineSyncService(client: server, database: database);
      repo = TaskRepo(client: server, database: database, syncService: sync);
      host = FakeWidgetHost();
      inbox = WidgetTaskInbox(host: host, repo: repo, currentUserId: () => signedIn);
    });

    tearDown(() async {
      await sync.dispose();
      await database.close();
    });

    test('saveQuickAddTask stores the task locally and queues it', () async {
      await saveQuickAddTask(
        const QuickAddTaskDraft(title: 'Call mum'),
        repo: repo,
        userId: userId,
        now: () => DateTime(2026, 11, 27, 9),
      );

      final row = (await database.getTasksForUser(userId)).single;
      expect(row.title, 'Call mum');
      expect(row.dueDate, '2026-11-27');
      expect(row.status, 'PENDING');
      expect(await database.getPendingTasks(userId), hasLength(1));
    });

    String inboxOf(List<Map<String, Object?>> items) =>
        WidgetTaskInbox.encode([for (final i in items) InboxTask.tryParse(i)!]);

    test('imports each inbox item once, keeps its id as the client id, and clears the inbox', () async {
      host.saved[WidgetTaskInbox.key] = inboxOf([
        {'id': 'A1B2C3D4-0000-4000-8000-000000000001', 'title': 'From Siri', 'dueDate': '2026-11-27'},
        {'id': 'A1B2C3D4-0000-4000-8000-000000000002', 'title': 'Undated'},
      ]);

      expect(await inbox.importAll(), 2);

      final rows = await database.getTasksForUser(userId);
      expect(rows.map((r) => r.title), unorderedEquals(['From Siri', 'Undated']));
      expect(rows.firstWhere((r) => r.title == 'From Siri').clientId,
          'a1b2c3d4-0000-4000-8000-000000000001');
      expect(rows.firstWhere((r) => r.title == 'From Siri').dueDate, '2026-11-27');
      expect(host.saved[WidgetTaskInbox.key], isNull);
    });

    test('is idempotent: an item already imported is not added again', () async {
      final items = inboxOf([
        {'id': 'A1B2C3D4-0000-4000-8000-000000000003', 'title': 'Once'},
      ]);
      host.saved[WidgetTaskInbox.key] = items;
      await inbox.importAll();
      // The intent wrote the same item again before the inbox was cleared.
      host.saved[WidgetTaskInbox.key] = items;

      expect(await inbox.importAll(), 0);
      expect(await database.getTasksForUser(userId), hasLength(1));
      expect(host.saved[WidgetTaskInbox.key], isNull);
    });

    test('signed out: items wait in the inbox', () async {
      signedIn = 0;
      final items = inboxOf([
        {'id': 'A1B2C3D4-0000-4000-8000-000000000004', 'title': 'Later'},
      ]);
      host.saved[WidgetTaskInbox.key] = items;

      expect(await inbox.importAll(), 0);
      expect(host.saved[WidgetTaskInbox.key], items);
    });

    test('bad entries are skipped', () {
      expect(WidgetTaskInbox.decode('not json'), isEmpty);
      expect(
        WidgetTaskInbox.decode(
          '[{"id": "", "title": "x"}, {"id": "a", "title": " "}, {"id": "b", "title": "ok", "dueDate": "soon"}]',
        ).map((t) => (t.id, t.dueDate)),
        [('b', null)],
      );
    });
  });
}
