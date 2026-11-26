import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/connectivity_service.dart';
import 'package:notes_app/views/widgets/connectivity_snackbar_listener.dart';

import 'support/fake_server.dart';

/// A checker status stream that counts its subscriptions.
class _FakeChecker {
  int listens = 0;
  late final StreamController<InternetConnectionStatus> controller =
      StreamController<InternetConnectionStatus>.broadcast(
        onListen: () => listens++,
      );

  void emit(InternetConnectionStatus status) => controller.add(status);
}

/// FE-05: one connectivity checker, shared, and one snackbar per change.
void main() {
  late _FakeChecker checker;
  late ConnectivityService connectivity;

  setUp(() {
    checker = _FakeChecker();
    connectivity = _CountingConnectivity(checker.controller.stream)..start();
  });

  tearDown(() => connectivity.dispose());

  group('ConnectivityService', () {
    test('subscribes to the checker once, however often it is started', () {
      for (var i = 0; i < 20; i++) {
        connectivity.start();
      }
      expect(checker.listens, 1);
    });

    test('emits only changes; slow counts as online', () async {
      final seen = <bool>[];
      connectivity.online.listen(seen.add);
      expect(connectivity.isOnline, isTrue, reason: 'optimistic before a check');

      for (final status in [
        InternetConnectionStatus.connected,
        InternetConnectionStatus.slow,
        InternetConnectionStatus.disconnected,
        InternetConnectionStatus.disconnected,
        InternetConnectionStatus.connected,
      ]) {
        checker.emit(status);
      }
      await pumpEventQueue();

      expect(seen, [true, false, true]);
      expect(connectivity.isOnline, isTrue);
    });
  });

  test('the sync service syncs when connectivity returns', () async {
    const userId = 42;
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final server = FakeServer();
    final sync = OfflineSyncService(
      client: server,
      database: database,
      connectivity: connectivity,
      minRetryDelay: const Duration(minutes: 1),
    );
    addTearDown(() async {
      await sync.dispose();
      await database.close();
    });

    sync.start(userId);
    await sync.requestSync();
    // Queued straight into the database, so only connectivity can upload it.
    await database.enqueueNote(
      userId: userId,
      title: 'queued',
      content: 'x',
      category: 'General',
      pinned: false,
      clientId: 'connectivity-client-id',
      payload: jsonEncode({'userId': userId, 'title': 'queued', 'content': 'x'}),
    );

    checker.emit(InternetConnectionStatus.disconnected);
    await pumpEventQueue(times: 200);
    expect(server.count('createNote'), 0);

    checker.emit(InternetConnectionStatus.connected);
    await pumpEventQueue(times: 200);
    expect(server.count('createNote'), 1);
    expect(checker.listens, 1, reason: 'the sync service shares the checker');
  });

  group('ConnectivitySnackbarListener', () {
    const offlineText = "You're offline. Changes are saved on this device.";
    const onlineText = 'Back online. Syncing your changes.';

    Future<void Function()> pumpApp(WidgetTester tester) async {
      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      final themeMode = ValueNotifier(ThemeMode.light);
      addTearDown(themeMode.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (context, mode, _) => ScreenUtilInit(
            designSize: const Size(412, 892),
            builder: (context, child) => ConnectivitySnackbarListener(
              connectivity: connectivity,
              messengerKey: messengerKey,
              child: MaterialApp(
                scaffoldMessengerKey: messengerKey,
                themeMode: mode,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                home: const Scaffold(body: SizedBox.shrink()),
              ),
            ),
          ),
        ),
      );
      return () => themeMode.value =
          themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }

    testWidgets('20 app rebuilds keep one subscription and one snackbar',
        (tester) async {
      // Created inside the test so its events run on the fake clock. (The
      // one from setUp is disposed in tearDown.)
      final fromSetUp = connectivity;
      addTearDown(fromSetUp.dispose);
      checker = _FakeChecker();
      connectivity = _CountingConnectivity(checker.controller.stream)..start();
      final toggleTheme = await pumpApp(tester);
      for (var i = 0; i < 20; i++) {
        toggleTheme();
        await tester.pump();
      }
      expect(checker.listens, 1);
      expect((connectivity as _CountingConnectivity).listens, 1);

      checker.emit(InternetConnectionStatus.connected);
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(SnackBar), findsNothing,
          reason: 'online at start is not news');

      // A flapping connection settles into one "offline" snackbar.
      checker.emit(InternetConnectionStatus.disconnected);
      await tester.pump(const Duration(milliseconds: 500));
      checker.emit(InternetConnectionStatus.connected);
      await tester.pump(const Duration(milliseconds: 500));
      checker.emit(InternetConnectionStatus.disconnected);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(offlineText), findsNothing, reason: 'debounced');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(offlineText), findsOneWidget);

      checker.emit(InternetConnectionStatus.connected);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(offlineText), findsNothing);
      expect(find.text(onlineText), findsOneWidget);

      // Let the snackbar time out so no timer is left running.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('the subscription is cancelled when the app is disposed',
        (tester) async {
      var cancelled = false;
      final source = StreamController<bool>.broadcast(
        onCancel: () => cancelled = true,
      );
      addTearDown(source.close);
      final service = _StreamConnectivity(source.stream);
      await tester.pumpWidget(
        ConnectivitySnackbarListener(
          connectivity: service,
          messengerKey: GlobalKey<ScaffoldMessengerState>(),
          child: const SizedBox.shrink(),
        ),
      );
      expect(source.hasListener, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(cancelled, isTrue);
    });
  });
}

class _StreamConnectivity extends ConnectivityService {
  final Stream<bool> _stream;

  _StreamConnectivity(this._stream) : super(const Stream.empty());

  @override
  Stream<bool> get online => _stream;
}

/// Counts subscriptions to [online].
class _CountingConnectivity extends ConnectivityService {
  int listens = 0;

  _CountingConnectivity(super.statusChanges);

  @override
  Stream<bool> get online => Stream.multi((listener) {
        listens++;
        final subscription = super.online.listen(
              listener.addSync,
              onError: listener.addErrorSync,
              onDone: listener.closeSync,
            );
        listener.onCancel = subscription.cancel;
      });
}
