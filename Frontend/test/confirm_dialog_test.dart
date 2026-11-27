import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/dto/request/task/update_task_request_dto.dart';
import 'package:notes_app/data/network/dto/response/note/note_details_response_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/viewmodel/reminder/reminder_state.dart';
import 'package:notes_app/viewmodel/reminder/reminder_viewmodel.dart';
import 'package:notes_app/viewmodel/session/session_viewmodel.dart';
import 'package:notes_app/viewmodel/task/task_state.dart';
import 'package:notes_app/viewmodel/task/task_viewmodel.dart';
import 'package:notes_app/views/screens/home/widgets/create_task_modal.dart';
import 'package:notes_app/views/screens/home/widgets/item_delete.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_form_modal.dart';
import 'package:notes_app/views/screens/home/widgets/reminder_item_card.dart';
import 'package:notes_app/views/screens/home/widgets/task_item_card.dart';
import 'package:notes_app/views/screens/note_details/note_details_screen.dart';
import 'package:notes_app/views/widgets/confirm_dialog.dart';

/// FIX-01: every delete asks first, and leaving a form with unsaved edits
/// asks "Discard changes?".
void main() {
  late _RecordingTasks tasks;
  late _RecordingReminders reminders;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<TaskRepo>(_UnusedTaskRepo());
    getIt.registerSingleton<ReminderRepo>(_UnusedReminderRepo());
    tasks = _RecordingTasks();
    reminders = _RecordingReminders();
  });

  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1700, 2600);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
  }

  Widget host(Widget home) => ProviderScope(
        overrides: [
          sessionUserIdProvider.overrideWith(_FixedUser.new),
          taskController.overrideWith(() => tasks),
          reminderController.overrideWith(() => reminders),
        ],
        child: ScreenUtilInit(
          designSize: const Size(412, 892),
          builder: (_, _) => MaterialApp(theme: AppTheme.lightTheme, home: home),
        ),
      );

  /// A screen with one button that runs [onPressed].
  Widget launcher(void Function(BuildContext, WidgetRef) onPressed) => host(
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) => Center(
              child: TextButton(
                onPressed: () => onPressed(context, ref),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

  final task = TaskItem(
    taskId: 5,
    title: 'Write report',
    dueDate: '2026-12-01',
    category: 'Work',
    priority: 'HIGH',
    clientId: 'c-5',
  );

  group('showConfirmDialog', () {
    testWidgets('styled with the tokens; Cancel has the focus', (tester) async {
      late Future<bool> answer;
      await tester.pumpWidget(launcher((context, _) {
        answer = showConfirmDialog(
          context,
          title: 'Delete reminder?',
          message: 'Gone for good.',
          confirmLabel: 'Delete',
        );
      }));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final shape = dialog.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(20));
      final cancel = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'));
      expect(cancel.autofocus, isTrue);
      expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
      expect(find.bySemanticsLabel('Delete reminder?'), findsWidgets);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
    });

    testWidgets('a tap outside or back cancels', (tester) async {
      late Future<bool> answer;
      await tester.pumpWidget(launcher((context, _) {
        answer = showConfirmDialog(context, title: 'T', message: 'M', confirmLabel: 'OK');
      }));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(await answer, isFalse);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(await answer, isFalse);
    });
  });

  group('deleting a task', () {
    Future<void> pumpCard(WidgetTester tester) async {
      tallScreen(tester);
      await tester.pumpWidget(host(Scaffold(
        body: Consumer(
          builder: (context, ref, _) => taskItemCard(
            context: context,
            task: task,
            onToggleComplete: (_) {},
            onDelete: () => confirmAndDeleteTask(context, ref, task),
            onStatusSelected: (_) {},
          ),
        ),
      )));
    }

    testWidgets('Cancel keeps the task', (tester) async {
      await pumpCard(tester);
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete task?'), findsOneWidget);
      expect(find.text('“Write report” will be permanently deleted.'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tasks.deleted, isEmpty);
      expect(find.text('Task deleted'), findsNothing);
    });

    testWidgets('Delete deletes it and says so, without Undo', (tester) async {
      await pumpCard(tester);
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(tasks.deleted, [5]);
      expect(find.text('Task deleted'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('the long-press menu deletes only after confirming', (tester) async {
      await pumpCard(tester);
      await tester.longPress(find.text('Write report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete task?'), findsOneWidget);
      expect(tasks.deleted, isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(tasks.deleted, [5]);
    });

    testWidgets("the edit sheet's Delete asks, then closes the sheet", (tester) async {
      tallScreen(tester);
      await tester.pumpWidget(launcher((context, _) => showCreateTaskModal(context, initial: task)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Edit task'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tasks.deleted, isEmpty);
      expect(find.text('Edit task'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(tasks.deleted, [5]);
      expect(find.text('Edit task'), findsNothing);
      expect(find.text('Task deleted'), findsOneWidget);
    });
  });

  group('deleting a reminder', () {
    ReminderItem reminder(String repeat) => ReminderItem(
          reminderId: 3,
          title: 'Call mom',
          remindAt: '2026-12-01T18:00:00',
          dueDate: '2026-12-01',
          dueTime: '18:00',
          status: 'PENDING',
          repeatInterval: repeat,
        );

    Future<void> pumpCard(WidgetTester tester, ReminderItem item) async {
      tallScreen(tester);
      await tester.pumpWidget(host(Scaffold(
        body: Consumer(
          builder: (context, ref, _) => reminderItemCard(
            context: context,
            reminder: item,
            onStatusChange: (_) {},
            onDelete: () => confirmAndDeleteReminder(context, ref, item),
          ),
        ),
      )));
    }

    testWidgets('Cancel keeps it; Delete deletes it', (tester) async {
      await pumpCard(tester, reminder('NONE'));
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete reminder?'), findsOneWidget);
      expect(find.text('“Call mom” will be permanently deleted.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(reminders.deleted, isEmpty);

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(reminders.deleted, [3]);
      expect(find.text('Reminder deleted'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('a repeating one says that all future reminders stop', (tester) async {
      await pumpCard(tester, reminder('DAILY'));
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(
        find.text('“Call mom” will be permanently deleted. This stops all future reminders.'),
        findsOneWidget,
      );
    });

    testWidgets("the edit sheet's Delete uses the same dialog", (tester) async {
      tallScreen(tester);
      final item = reminder('WEEKLY');
      await tester.pumpWidget(launcher((context, _) => showReminderFormModal(context, initial: item)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.textContaining('This stops all future reminders.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(reminders.deleted, [3]);
      expect(find.text('Edit reminder'), findsNothing);
    });
  });

  group('Discard changes?', () {
    Future<void> openSheet(WidgetTester tester, {TaskItem? initial}) async {
      tallScreen(tester);
      await tester.pumpWidget(launcher((context, _) => showCreateTaskModal(context, initial: initial)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('an untouched task sheet closes without asking', (tester) async {
      await openSheet(tester);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('New task'), findsNothing);

      await openSheet(tester, initial: task);
      await tester.tapAt(const Offset(5, 5)); // the scrim
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Edit task'), findsNothing);
    });

    testWidgets('an edited task sheet asks; Cancel keeps the edits', (tester) async {
      await openSheet(tester, initial: task);
      await tester.enterText(find.widgetWithText(TextField, 'Write report'), 'Write the report');
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Write the report'), findsOneWidget);

      await tester.binding.handlePopRoute(); // system back
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Edit task'), findsNothing);
      expect(tasks.updates, 0);
    });

    testWidgets('changing a chip back and forth counts as unchanged', (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('High'));
      await tester.pump();
      await tester.tap(find.text('Medium'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('New task'), findsNothing);
    });

    testWidgets('a new reminder with a title asks before closing', (tester) async {
      tallScreen(tester);
      await tester.pumpWidget(launcher((context, _) => showReminderFormModal(context)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing, reason: 'nothing changed');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Call mom');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
      await tester.pumpAndSettle();
      expect(find.text('New reminder'), findsNothing);
    });
  });

  group('note editor', () {
    late _FakeNoteRepo notes;

    Future<void> openNote(WidgetTester tester) async {
      tallScreen(tester);
      notes = _FakeNoteRepo();
      getIt.registerSingleton<NoteRepo>(notes);
      await tester.pumpWidget(launcher((context, _) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteDetailsScreen(noteId: 9)),
          )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Edit note'), findsOneWidget);
    }

    testWidgets('back without changes leaves at once', (tester) async {
      await openNote(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Edit note'), findsNothing);
    });

    testWidgets('back after an edit asks; Discard leaves', (tester) async {
      await openNote(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Groceries'), 'Groceries!');
      await tester.pump();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit note'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Edit note'), findsNothing);
      expect(notes.deleted, isEmpty);
    });

    testWidgets('pinning counts as a change', (tester) async {
      await openNote(tester);
      await tester.tap(find.byTooltip('Pin'));
      await tester.pump();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('delete: Cancel keeps the note, Delete deletes it', (tester) async {
      await openNote(tester);
      await tester.tap(find.bySemanticsLabel('Delete note'));
      await tester.pumpAndSettle();
      expect(find.text('Delete note?'), findsOneWidget);
      expect(find.text('“Groceries” will be permanently deleted.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(notes.deleted, isEmpty);
      expect(find.text('Edit note'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Delete note'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(notes.deleted, [9]);
      expect(find.text('Edit note'), findsNothing, reason: 'no discard prompt after a delete');
      expect(find.text('Note deleted'), findsOneWidget);
    });
  });
}

class _FixedUser extends SessionUserIdViewmodel {
  @override
  int build() => 7;
}

class _UnusedTaskRepo implements TaskRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedReminderRepo implements ReminderRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingTasks extends TaskViewmodel {
  final List<int> deleted = [];
  int updates = 0;

  @override
  Future<TaskState> build() async => const TaskState();

  @override
  Future<void> deleteTask(int taskId) async => deleted.add(taskId);

  @override
  Future<void> updateTask(UpdateTaskRequestDto requestDto) async => updates++;
}

class _RecordingReminders extends ReminderViewmodel {
  final List<int> deleted = [];

  @override
  Future<ReminderState> build() async => const ReminderState();

  @override
  Future<void> deleteReminder(int reminderId) async => deleted.add(reminderId);
}

class _FakeNoteRepo implements NoteRepo {
  final List<int> deleted = [];

  @override
  Future<NoteDetailsResponseDto> getNoteDetails(int userId, int id) async => NoteDetailsResponseDto(
        success: true,
        data: NoteDetailsData(noteId: id, title: 'Groceries', content: 'Milk, eggs', category: 'General'),
      );

  @override
  Future<void> deleteNote(int userId, int id) async => deleted.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
