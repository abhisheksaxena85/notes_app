import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/viewmodel/sync/sync_status_viewmodel.dart';
import 'package:notes_app/views/screens/home/widgets/sync_failures_banner.dart';

/// Stands in for the real viewmodel: the database side of retry and discard
/// is covered in sync_service_test.dart.
class FakeSyncStatusViewmodel extends SyncStatusViewmodel {
  FakeSyncStatusViewmodel(this.failures);

  final StreamController<List<SyncFailure>> failures;
  final List<String> actions = [];

  @override
  Stream<List<SyncFailure>> build() => failures.stream;

  @override
  Future<void> retryAll() async => actions.add('retryAll');

  @override
  Future<void> retry(SyncFailure failure) async => actions.add('retry ${failure.title}');

  @override
  Future<void> discard(SyncFailure failure) async =>
      actions.add('discard ${failure.title}');
}

SyncFailure failure(String title, {int queueId = 1}) => SyncFailure(
      entity: SyncEntity.note,
      queueId: queueId,
      localId: queueId,
      title: title,
      lastError: 'Content must be at most 100000 characters',
      attempts: 1,
    );

/// FE-03: refused items are surfaced with retry and discard.
void main() {
  late StreamController<List<SyncFailure>> failures;
  late FakeSyncStatusViewmodel viewmodel;

  setUp(() {
    failures = StreamController<List<SyncFailure>>();
    viewmodel = FakeSyncStatusViewmodel(failures);
  });

  tearDown(() => failures.close());

  Future<void> pumpBanner(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [syncStatusController.overrideWith(() => viewmodel)],
        child: ScreenUtilInit(
          designSize: const Size(412, 892),
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: SyncFailuresBanner()),
          ),
        ),
      ),
    );
  }

  testWidgets('shows nothing when every change synced', (tester) async {
    await pumpBanner(tester);
    failures.add(const []);
    await tester.pump();
    expect(find.textContaining("couldn't sync"), findsNothing);
  });

  testWidgets('lists a refused note and discards it only after confirmation',
      (tester) async {
    await pumpBanner(tester);
    failures.add([failure('Huge note')]);
    await tester.pump();

    expect(find.text("1 item couldn't sync"), findsOneWidget);
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Huge note'), findsOneWidget);
    expect(find.textContaining('Content must be at most'), findsOneWidget);

    await tester.tap(find.byTooltip('Discard'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(viewmodel.actions, isEmpty);

    await tester.tap(find.byTooltip('Discard'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();
    expect(viewmodel.actions, ['discard Huge note']);

    // Once the list is empty the banner and the sheet go away.
    failures.add(const []);
    await tester.pumpAndSettle();
    expect(find.textContaining("couldn't sync"), findsNothing);
    expect(find.text('Huge note'), findsNothing);
  });

  testWidgets('retry and retry all call the viewmodel', (tester) async {
    await pumpBanner(tester);
    failures.add([failure('First'), failure('Second', queueId: 2)]);
    await tester.pump();
    expect(find.text("2 items couldn't sync"), findsOneWidget);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Retry').first);
    await tester.tap(find.text('Retry all'));
    await tester.pump();

    expect(viewmodel.actions, ['retry First', 'retryAll']);
  });

  testWidgets('a refused edit says the server version comes back', (tester) async {
    await pumpBanner(tester);
    failures.add([
      const SyncFailure(
        entity: SyncEntity.task,
        operation: 'update',
        queueId: 7,
        localId: 3,
        title: 'Plan trip',
        lastError: 'Refused',
        attempts: 1,
      ),
    ]);
    await tester.pump();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Task edit'), findsOneWidget);

    await tester.tap(find.byTooltip('Discard'));
    await tester.pumpAndSettle();
    expect(find.textContaining("server's version"), findsOneWidget);
  });
}
