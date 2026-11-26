import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/database/reminder_database_mapper.dart';
import 'package:notes_app/data/local/database/task_database_mapper.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/themes/app_theme.dart';
import 'package:notes_app/views/screens/home/widgets/task_item_card.dart';

/// Records create calls so tests can assert what the sync actually uploads.
class RecordingApiClient extends ApiClient {
  RecordingApiClient() : super(dioClient: DioClient(Dio()));

  final List<CreateTaskRequestDto> createdTasks = [];
  final List<CreateReminderRequestDto> createdReminders = [];
  int _nextId = 500;

  Response _ok(String path, Map<String, dynamic> data) => Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 201,
        data: {'success': true, 'data': data},
      );

  @override
  Future<Response> createTask(CreateTaskRequestDto requestDto) async {
    createdTasks.add(requestDto);
    return _ok('/tasks', {'taskId': _nextId++});
  }

  @override
  Future<Response> createReminder(CreateReminderRequestDto requestDto) async {
    createdReminders.add(requestDto);
    return _ok('/reminders', {'reminderId': _nextId++});
  }
}

void main() {
  late AppDatabase database;
  late RecordingApiClient client;
  late TaskRepo taskRepo;
  late ReminderRepo reminderRepo;
  late OfflineSyncService syncService;
  const userId = 42;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    client = RecordingApiClient();
    syncService = OfflineSyncService(client: client, database: database);
    taskRepo = TaskRepo(
      client: client,
      database: database,
      syncService: syncService,
    );
    reminderRepo = ReminderRepo(
      client: client,
      database: database,
      syncService: syncService,
    );
  });

  tearDown(() async {
    await syncService.dispose();
    await database.close();
  });

  /// Turns syncing on only after the test has made its local changes, so the
  /// upload sees the final state.
  Future<void> syncNow() {
    syncService.setUserId(userId);
    return syncService.requestSync();
  }

  Future<int> queueTask() => taskRepo.enqueueTask(
        CreateTaskRequestDto(userId: userId, title: 'Offline task'),
      );

  Future<int> queueReminder() => reminderRepo.enqueueReminder(
        CreateReminderRequestDto(
          userId: userId,
          title: 'Offline reminder',
          remindAt: '2099-01-01T09:00:00',
          dueDate: '2099-01-01',
          dueTime: '09:00',
        ),
      );

  group('Unsynced (local-only) items', () {
    test('deleting a queued task also drops it from the upload queue', () async {
      final localId = await queueTask();

      await taskRepo.deleteTask(userId, -localId);
      await syncNow();

      expect(await database.getPendingTasks(userId), isEmpty);
      expect(client.createdTasks, isEmpty);
      expect(await taskRepo.getCachedTasks(userId), isEmpty);
    });

    test('completing a queued task uploads it as COMPLETED', () async {
      final localId = await queueTask();

      await taskRepo.toggleTaskStatus(userId, -localId, true);
      await syncNow();

      expect(client.createdTasks, hasLength(1));
      expect(client.createdTasks.single.status, 'COMPLETED');
      expect(client.createdTasks.single.isCompleted, isTrue);
    });

    test('deleting a queued reminder also drops it from the upload queue',
        () async {
      final localId = await queueReminder();

      await reminderRepo.deleteReminder(userId, -localId);
      await syncNow();

      expect(await database.getPendingReminders(userId), isEmpty);
      expect(client.createdReminders, isEmpty);
    });

    test('changing a queued reminder status uploads the new status', () async {
      final localId = await queueReminder();

      await reminderRepo.updateReminderStatus(userId, -localId, 'REJECTED');
      await syncNow();

      expect(client.createdReminders.single.status, 'REJECTED');
    });
  });

  group('Missed / rejected status', () {
    final now = DateTime(2026, 11, 19, 12, 0);

    test('an overdue PENDING task is displayed as MISSED', () {
      expect(
        TaskItem(title: 't', dueDate: '2026-11-19', dueTime: '09:00')
            .effectiveStatus(now),
        'MISSED',
      );
      expect(
        TaskItem(title: 't', dueDate: '2026-11-18').effectiveStatus(now),
        'MISSED',
      );
    });

    test('not-yet-due, undated, completed and rejected tasks keep their status',
        () {
      // Date without time is due at end of day, so still pending at noon.
      expect(TaskItem(title: 't', dueDate: '2026-11-19').effectiveStatus(now),
          'PENDING');
      expect(TaskItem(title: 't').effectiveStatus(now), 'PENDING');
      expect(
        TaskItem(title: 't', dueDate: '2026-11-01', isCompleted: true)
            .effectiveStatus(now),
        'COMPLETED',
      );
      expect(
        TaskItem(title: 't', dueDate: '2026-11-01', status: 'REJECTED')
            .effectiveStatus(now),
        'REJECTED',
      );
    });

    test('only one-off reminders become MISSED', () {
      final past = ReminderItem(
        title: 'r',
        remindAt: '2026-11-19T08:00:00',
        dueDate: '2026-11-19',
        dueTime: '08:00',
      );
      expect(past.effectiveStatus(now), 'MISSED');
      expect(past.copyWith(repeatInterval: 'DAILY').effectiveStatus(now),
          'PENDING');
      expect(
        ReminderItem(title: 'r', remindAt: '2026-11-19T08:00:00')
            .effectiveStatus(now),
        'MISSED',
      );
    });

    test('rejecting a queued task uploads it as REJECTED, not completed',
        () async {
      final localId = await queueTask();

      await taskRepo.setTaskStatus(userId, -localId, 'REJECTED');
      await syncNow();

      final cached = await taskRepo.getCachedTasks(userId);
      expect(cached.single.status, 'REJECTED');
      expect(client.createdTasks.single.status, 'REJECTED');
      expect(client.createdTasks.single.isCompleted, isFalse);
    });
  });

  testWidgets('long-pressing a task card lets the user mark it REJECTED',
      (tester) async {
    String? selected;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 892),
        builder: (context, child) => MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => taskItemCard(
                context: ctx,
                task: TaskItem(taskId: 1, title: 'Reject me'),
                onToggleComplete: (_) {},
                onStatusSelected: (status) => selected = status,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Reject me'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rejected'));
    await tester.pumpAndSettle();

    expect(selected, 'REJECTED');
  });

  group('Saving a server copy over an existing cached row', () {
    test('saveServerTask updates in place instead of violating uniqueness',
        () async {
      await database.replaceServerTasks(userId, [
        TaskDatabaseMapper.fromTaskItem(
          userId,
          TaskItem(taskId: 7, title: 'Before'),
        ),
      ]);

      await database.saveServerTask(
        TaskDatabaseMapper.fromTaskItem(
          userId,
          TaskItem(taskId: 7, title: 'After', status: 'COMPLETED', isCompleted: true),
        ),
      );

      final tasks = await taskRepo.getCachedTasks(userId);
      expect(tasks, hasLength(1));
      expect(tasks.single.title, 'After');
      expect(tasks.single.status, 'COMPLETED');
    });

    test('saveServerReminder updates in place instead of violating uniqueness',
        () async {
      await database.replaceServerReminders(userId, [
        ReminderDatabaseMapper.fromReminderItem(
          userId,
          ReminderItem(reminderId: 9, title: 'Before', remindAt: '2099-01-01T09:00:00'),
        ),
      ]);

      await database.saveServerReminder(
        ReminderDatabaseMapper.fromReminderItem(
          userId,
          ReminderItem(reminderId: 9, title: 'After', remindAt: '2099-01-01T10:00:00'),
        ),
      );

      final reminders = await reminderRepo.getCachedReminders(userId);
      expect(reminders, hasLength(1));
      expect(reminders.single.title, 'After');
    });
  });
}
