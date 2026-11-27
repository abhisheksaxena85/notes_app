import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/network/dto/request/login/login_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/update_task_request_dto.dart';
import 'package:notes_app/data/network/dto/response/note/note_details_response_dto.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/utils/services/note_data_transfer_service.dart';
import 'package:notes_app/utils/services/note_export_file.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/viewmodel/session/session_viewmodel.dart';
import 'package:notes_app/viewmodel/task/task_state.dart';
import 'package:notes_app/viewmodel/task/task_viewmodel.dart';
import 'package:notes_app/views/screens/home/widgets/create_task_modal.dart';
import 'package:notes_app/views/screens/note_details/note_details_screen.dart';
import 'package:notes_app/views/widgets/undo_delete.dart';

import 'support/fake_server.dart';

/// FE-06: friendly errors, a fresh note screen per note, undo on delete,
/// task editing and file export.
void main() {
  setUp(() async {
    await getIt.reset();
  });

  Widget host(Widget home, {List overrides = const []}) => ProviderScope(
        overrides: [
          sessionUserIdProvider.overrideWith(_FixedUser.new),
          ...overrides,
        ],
        child: ScreenUtilInit(
          designSize: const Size(412, 892),
          builder: (_, _) => MaterialApp(theme: AppTheme.lightTheme, home: home),
        ),
      );

  void tallScreen(WidgetTester tester) {
    // Wide enough for the test font (Ahem), which is wider than Inter.
    tester.view.physicalSize = const Size(1700, 2600);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
  }

  group('note details', () {
    testWidgets('opening note B after note A never shows note A', (tester) async {
      tallScreen(tester);
      final repo = _FakeNoteRepo();
      getIt.registerSingleton<NoteRepo>(repo);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(host(Navigator(
        key: navigator,
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const Scaffold()),
      )));

      navigator.currentState!.push(MaterialPageRoute(builder: (_) => const NoteDetailsScreen(noteId: 1)));
      await tester.pump();
      repo.complete(1, 'Alpha title', 'Alpha body');
      await tester.pumpAndSettle();
      expect(find.text('Alpha title'), findsOneWidget);

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      navigator.currentState!.push(MaterialPageRoute(builder: (_) => const NoteDetailsScreen(noteId: 2)));
      // Every frame while note 2 loads: nothing of note 1.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        expect(find.text('Alpha title'), findsNothing);
        expect(find.text('Alpha body'), findsNothing);
      }
      repo.complete(2, 'Beta title', 'Beta body');
      await tester.pumpAndSettle();
      expect(find.text('Beta title'), findsOneWidget);
      expect(find.text('Alpha title'), findsNothing);

      // The closed screen's state was disposed: reopening note 1 loads again.
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      navigator.currentState!.push(MaterialPageRoute(builder: (_) => const NoteDetailsScreen(noteId: 1)));
      await tester.pump();
      expect(repo.requests, [1, 2, 1]);
      repo.complete(1, 'Alpha title', 'Alpha body');
      await tester.pumpAndSettle();
    });

    testWidgets('a failed load shows a friendly message, not the exception', (tester) async {
      tallScreen(tester);
      final repo = _FakeNoteRepo();
      getIt.registerSingleton<NoteRepo>(repo);
      await tester.pumpWidget(host(const NoteDetailsScreen(noteId: 9)));
      repo.fail(9, DioException.connectionTimeout(
        timeout: const Duration(seconds: 10),
        requestOptions: RequestOptions(path: '/notes/get-note-details'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('took too long'), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });
  });

  group('deleteWithUndo', () {
    Future<_UndoProbe> pumpProbe(WidgetTester tester, {Object? failWith}) async {
      final probe = _UndoProbe(failWith: failWith);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(children: [
              for (final name in ['a', 'b'])
                TextButton(
                  onPressed: () => deleteWithUndo(
                    messenger: ScaffoldMessenger.of(context),
                    message: 'Deleted $name',
                    hide: () => probe.hidden.add(name),
                    restore: () => probe.hidden.remove(name),
                    delete: () => probe.delete(name),
                  ),
                  child: Text('delete $name'),
                ),
            ]),
          ),
        ),
      ));
      return probe;
    }

    testWidgets('Undo puts the item back and deletes nothing', (tester) async {
      final probe = await pumpProbe(tester);
      await tester.tap(find.text('delete a'));
      await tester.pump();
      expect(probe.hidden, {'a'});
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(probe.hidden, isEmpty);
      expect(probe.deleted, isEmpty);
    });

    testWidgets('without Undo the delete runs when the snackbar times out', (tester) async {
      final probe = await pumpProbe(tester);
      await tester.tap(find.text('delete a'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(probe.deleted, isEmpty, reason: 'still inside the undo window');

      await tester.pump(undoWindow);
      await tester.pumpAndSettle();
      expect(probe.deleted, ['a']);
      expect(probe.hidden, {'a'}, reason: 'stays hidden after the delete');
    });

    testWidgets('a second delete commits the first right away', (tester) async {
      final probe = await pumpProbe(tester);
      await tester.tap(find.text('delete a'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.tap(find.text('delete b'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(probe.deleted, ['a']);
      expect(find.text('Deleted b'), findsOneWidget);
    });

    testWidgets('a failed delete restores the item with a friendly message', (tester) async {
      final probe = await pumpProbe(tester, failWith: FakeServer.offline());
      await tester.tap(find.text('delete a'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // entrance animation
      await tester.pump(undoWindow);
      await tester.pumpAndSettle();
      expect(probe.hidden, isEmpty);
      expect(find.textContaining('No internet connection'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });
  });

  group('task form', () {
    final task = TaskItem(
      taskId: 5,
      title: 'Write report',
      description: 'Quarterly',
      dueDate: '2026-12-01',
      dueTime: '09:30',
      category: 'Work',
      priority: 'HIGH',
      clientId: 'c-5',
    );

    testWidgets('edit: prefilled, and Save sends only what changed', (tester) async {
      tallScreen(tester);
      getIt.registerSingleton<TaskRepo>(_UnusedTaskRepo());
      final tasks = _RecordingTasks();
      await tester.pumpWidget(host(
        Scaffold(body: SingleChildScrollView(child: TaskFormModal(initial: task))),
        overrides: [taskController.overrideWith(() => tasks)],
      ));

      expect(find.text('Edit Task'), findsOneWidget);
      expect(find.text('Write report'), findsOneWidget);
      expect(find.text('Quarterly'), findsOneWidget);
      expect(find.text('2026-12-01'), findsOneWidget);
      expect(find.text('09:30'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Write report'), 'Write the report');
      await tester.tap(find.text('LOW'));
      await tester.pump();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(tasks.updates, hasLength(1));
      final update = tasks.updates.single;
      expect(update.taskId, 5);
      expect(update.toJson(), {'taskId': 5, 'title': 'Write the report', 'priority': 'LOW'});
      expect(tasks.created, 0);
    });

    testWidgets('create: a failure shows a friendly message', (tester) async {
      tallScreen(tester);
      getIt.registerSingleton<TaskRepo>(_UnusedTaskRepo());
      final tasks = _RecordingTasks(failWith: FakeServer.status(500, 'java.lang.NullPointerException'));
      await tester.pumpWidget(host(
        const Scaffold(body: SingleChildScrollView(child: TaskFormModal())),
        overrides: [taskController.overrideWith(() => tasks)],
      ));
      expect(find.text('New Task'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Buy milk');
      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong on our side'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });
  });

  testWidgets('login: a failed sign-in stays an error with a friendly message',
      (tester) async {
    tallScreen(tester);
    getIt.registerSingleton<ApiClient>(_RejectingLoginClient());
    // The screen's own layout is covered elsewhere; this checks the state the
    // Sign In button renders from (data = "Sign In", error = "Retry").
    await tester.pumpWidget(host(Scaffold(
      body: Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => ref.read(loginController.notifier).loginUser(context),
          child: Text(ref.watch(loginController).when(
                data: (_) => 'Sign In',
                error: (_, _) => 'Retry',
                loading: () => 'Loading',
              )),
        ),
      ),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(find.textContaining('DioException'), findsNothing);
  });

  group('NoteExportFile', () {
    test('file name, extension and type per format', () {
      final at = DateTime(2026, 11, 27, 9, 5);
      expect(NoteExportFile.fileName(NoteExportFormat.csv, at), 'daymark-notes-20261127-0905.csv');
      expect(NoteExportFile.fileName(NoteExportFormat.json, at), endsWith('.json'));
      expect(NoteExportFile.fileName(NoteExportFormat.txt, at), endsWith('.txt'));
      expect(NoteExportFile.mimeType(NoteExportFormat.json), 'application/json');
      expect(NoteExportFile.mimeType(NoteExportFormat.csv), 'text/csv');
    });

    test('writes the whole export as UTF-8', () async {
      final dir = await Directory.systemTemp.createTemp('daymark_export_');
      addTearDown(() => dir.delete(recursive: true));
      final big = 'x' * (2 * 1024 * 1024); // past the Android clipboard limit
      final content = '{"title":"Café ☕","content":"$big"}';
      final file = await NoteExportFile.write(content, NoteExportFormat.json,
          directory: dir, now: DateTime(2026, 1, 2, 3, 4));
      expect(file.path, endsWith('daymark-notes-20260102-0304.json'));
      expect(await file.readAsString(), content);
    });
  });
}

class _FixedUser extends SessionUserIdViewmodel {
  @override
  int build() => 7;
}

/// Note details on demand: each request waits until the test completes it.
class _FakeNoteRepo implements NoteRepo {
  final List<int> requests = [];
  final Map<int, Completer<NoteDetailsResponseDto>> _pending = {};

  @override
  Future<NoteDetailsResponseDto> getNoteDetails(int userId, int id) {
    requests.add(id);
    return (_pending[id] = Completer()).future;
  }

  void complete(int id, String title, String content) {
    _pending.remove(id)!.complete(NoteDetailsResponseDto(
      success: true,
      data: NoteDetailsData(noteId: id, title: title, content: content, category: 'General'),
    ));
  }

  void fail(int id, Object error) => _pending.remove(id)!.completeError(error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UndoProbe {
  _UndoProbe({this.failWith});

  final Object? failWith;
  final Set<String> hidden = {};
  final List<String> deleted = [];

  Future<void> delete(String name) async {
    if (failWith != null) throw failWith!;
    deleted.add(name);
  }
}

class _UnusedTaskRepo implements TaskRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingTasks extends TaskViewmodel {
  _RecordingTasks({this.failWith});

  final Object? failWith;
  final List<UpdateTaskRequestDto> updates = [];
  int created = 0;

  @override
  Future<TaskState> build() async => const TaskState();

  @override
  Future<void> updateTask(UpdateTaskRequestDto requestDto) async {
    if (failWith != null) throw failWith!;
    updates.add(requestDto);
  }

  @override
  Future<void> createTask({
    required String title,
    String? description,
    String? dueDate,
    String? dueTime,
    String? category,
    String? priority,
  }) async {
    if (failWith != null) throw failWith!;
    created++;
  }
}

class _RejectingLoginClient extends ApiClient {
  _RejectingLoginClient() : super(dioClient: DioClient(Dio()));

  @override
  Future<Response> login(LoginRequestDto requestDto) async {
    throw FakeServer.status(401, 'Invalid email or password');
  }
}
