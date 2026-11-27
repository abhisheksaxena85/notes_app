import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/background_graph.dart';
import 'package:notes_app/views/screens/quick_add/quick_add_task_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_server.dart';
import 'support/fake_widget_host.dart';

/// FIX-02: the app QuickAddTaskActivity runs (the Tasks widget's +), with the
/// light task graph over an in-memory database and a fake server.
void main() {
  const userId = 7;
  late AppDatabase database;
  late FakeServer server;
  late FakeWidgetHost host;
  late int finished;

  setUp(() async {
    // No network in tests: the test font stands in for Inter.
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await Preference.init();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    database = AppDatabase.forTesting(NativeDatabase.memory());
    server = FakeServer();
    host = FakeWidgetHost();
    finished = 0;
  });

  tearDown(() async {
    await database.close();
  });

  TaskGraph graphFor(int user) {
    final sync = OfflineSyncService(client: server, database: database);
    return _OpenGraph(
      userId: user,
      database: database,
      sync: sync,
      taskRepo: TaskRepo(client: server, database: database, syncService: sync),
    );
  }

  Future<void> pumpApp(WidgetTester tester, Future<TaskGraph> Function() open) async {
    await tester.pumpWidget(QuickAddTaskApp(
      openGraph: open,
      widgetHost: host,
      onFinish: () => finished++,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('opens the sheet and saves the task to the device, the widget and the server',
      (tester) async {
    await pumpApp(tester, () async => graphFor(userId));

    expect(find.text('New task'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
    expect(find.byKey(const Key('quickAddTitle')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('quickAddTitle')), 'Water the plants');
    await tester.pump();
    await tester.tap(find.text('Add task'));
    // The save, the widget refresh and the short upload (in-memory database,
    // fake server) finish within a few frames.
    for (var i = 0; i < 50 && finished == 0; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(finished, 1, reason: 'the pop-up closes after saving');
    final rows = await database.getTasksForUser(userId);
    expect(rows.map((t) => t.title), ['Water the plants']);
    expect(server.tasks.values.map((t) => t['title']), ['Water the plants'],
        reason: 'uploaded straight away');
    final widgetTasks = host.snapshot!['tasks'] as Map<String, dynamic>;
    expect(widgetTasks['count'], 1);
    expect((widgetTasks['items'] as List).map((t) => t['title']), ['Water the plants']);
    expect(host.updates, greaterThan(0), reason: 'the widget redraws at once');
  });

  testWidgets('nobody signed in: "Sign in to Daymark", nothing saved', (tester) async {
    await pumpApp(tester, () async => graphFor(0));

    expect(find.text('Sign in to Daymark'), findsOneWidget);
    expect(find.byKey(const Key('quickAddTitle')), findsNothing);
    await tester.tap(find.text('Close'));
    expect(finished, 1);
  });

  testWidgets('a failure to start shows the real error in debug builds', (tester) async {
    await pumpApp(tester, () async => throw StateError('database is locked'));

    expect(find.text('Something went wrong'), findsOneWidget);
    // Tests run in debug mode; release builds show "Open Daymark and try again."
    expect(find.text('Quick add could not start: Bad state: database is locked'), findsOneWidget);
  });

  test('release builds keep every drawable the notification plugin looks up by name', () {
    // The root cause of FIX-02: resource shrinking dropped ic_stat_daymark,
    // so NotificationService.init threw PlatformException(invalid_icon).
    final source = File('lib/utils/services/notification_service.dart').readAsStringSync();
    final names = {
      for (final m in RegExp(r"(?:AndroidInitializationSettings\(|icon: )'(\w+)'").allMatches(source))
        m.group(1)!,
    };
    expect(names, contains('ic_stat_daymark'));
    final keep = File('android/app/src/main/res/raw/keep.xml').readAsStringSync();
    for (final name in names) {
      expect(keep, contains('@drawable/$name'), reason: '$name must survive shrinkResources');
      expect(File('android/app/src/main/res/drawable/$name.xml').existsSync(), isTrue);
    }
  });
}

/// A TaskGraph over the test's database (the real one opens the device's).
class _OpenGraph extends TaskGraph {
  _OpenGraph({
    required super.userId,
    required super.database,
    required super.sync,
    required super.taskRepo,
  });

  /// The test closes the database itself.
  @override
  Future<void> close() => sync.dispose();
}
