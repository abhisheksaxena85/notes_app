import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/local/shared_preference/preference_keys.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/repository/home/home_repo.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/repository/profile/profile_repo.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_server.dart';

class _RecordingSessionService extends SessionService {
  _RecordingSessionService({
    required super.preference,
    required super.database,
    required super.syncService,
    required super.profileRepo,
  });

  final List<int> cancelledFor = [];

  @override
  Future<void> cancelReminderNotifications(int userId) async {
    cancelledFor.add(userId);
  }
}

/// FE-01: one session source of truth; switching users swaps all data.
void main() {
  const userA = 1;
  const userB = 2;
  late AppDatabase database;
  late FakeServer server;
  late OfflineSyncService sync;
  late _RecordingSessionService session;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Preference.init();
    await getIt.reset();

    database = AppDatabase.forTesting(NativeDatabase.memory());
    server = FakeServer();
    sync = OfflineSyncService(
      client: server,
      database: database,
      minRetryDelay: const Duration(minutes: 1),
      maxRetryDelay: const Duration(minutes: 8),
    );
    getIt
      ..registerSingleton<Preference>(Preference())
      ..registerSingleton<AppDatabase>(database)
      ..registerSingleton<ApiClient>(server)
      ..registerSingleton<OfflineSyncService>(sync)
      ..registerSingleton<HomeRepo>(
          HomeRepo(client: server, database: database, syncService: sync))
      ..registerSingleton<NoteRepo>(
          NoteRepo(client: server, database: database, syncService: sync))
      ..registerSingleton<TaskRepo>(
          TaskRepo(client: server, database: database, syncService: sync))
      ..registerSingleton<ReminderRepo>(
          ReminderRepo(client: server, database: database, syncService: sync))
      ..registerSingleton<ProfileRepo>(
          ProfileRepo(client: server, database: database));
    session = _RecordingSessionService(
      preference: getIt<Preference>(),
      database: database,
      syncService: sync,
      profileRepo: getIt<ProfileRepo>(),
    );
    getIt.registerSingleton<SessionService>(session);
    session.restore();

    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await sync.dispose();
    await session.dispose();
    await database.close();
    await getIt.reset();
  });

  Future<List<String?>> homeTitles() async {
    // Let refreshes and stream updates settle first.
    await sync.runExclusive(() async {});
    await pumpEventQueue();
    final state = await container.read(homeController.future);
    return [for (final note in state.notesData?.data ?? []) note.title];
  }

  test('logging out A and in as B shows only B\'s data, without a restart',
      () async {
    container.listen(homeController, (_, _) {});
    server.notes[7] = {'noteId': 7, 'userId': userB, 'title': 'B note', 'content': 'b'};

    await session.login(userA);
    await getIt<NoteRepo>().enqueueNote(
      CreateNoteRequestDto(userId: userA, title: 'A note', content: 'a'),
    );
    await sync.requestSync();
    expect(await homeTitles(), ['A note']);

    await session.logout();
    expect(container.read(sessionUserIdProvider), 0);
    expect(await homeTitles(), isEmpty);

    await session.login(userB);
    expect(container.read(sessionUserIdProvider), userB);
    expect(await homeTitles(), ['B note']);
  });

  test('logout wipes the user\'s cached rows, queues and profile', () async {
    await session.login(userA);
    await sync.runExclusive(() async {}); // profile refresh
    await pumpEventQueue();
    await getIt<NoteRepo>().enqueueNote(
      CreateNoteRequestDto(userId: userA, title: 'synced', content: 'a'),
    );
    await sync.requestSync();
    // Offline from here: this one stays queued.
    server.onRequest = (_, _) => throw FakeServer.offline();
    await getIt<TaskRepo>()
        .enqueueTask(CreateTaskRequestDto(userId: userA, title: 'unsynced'));
    await sync.requestSync();

    expect(await session.unsyncedChangeCount(), 1);
    expect(await database.getProfile(userA), isNotNull);

    await session.logout();

    expect(session.isLoggedIn, isFalse);
    expect(getIt<Preference>().getInt(PreferenceKeys.USER_ID), isNull);
    expect(await database.getNotesForUser(userA), isEmpty);
    expect(await database.getTasksForUser(userA), isEmpty);
    expect(await database.getPendingTasks(userA), isEmpty);
    expect(await database.countUnsyncedChanges(userA), 0);
    expect(await database.getProfile(userA), isNull);
    expect(session.cancelledFor, [userA]);
  });

  test('logout without wiping keeps the rows but stops syncing them', () async {
    await session.login(userA);
    server.onRequest = (_, _) => throw FakeServer.offline();
    await getIt<NoteRepo>().enqueueNote(
      CreateNoteRequestDto(userId: userA, title: 'kept', content: 'a'),
    );
    await sync.requestSync();

    await session.logout(wipeLocalData: false);
    server.onRequest = null;
    await sync.requestSync();

    expect(sync.userId, isNull);
    expect(server.notes, isEmpty);
    expect(await database.countUnsyncedChanges(userA), 1);
  });

  test('the session survives an app restart', () async {
    await session.login(userA);

    final restarted = SessionService(
      preference: getIt<Preference>(),
      database: database,
      syncService: sync,
      profileRepo: getIt<ProfileRepo>(),
    )..restore();

    expect(restarted.userId, userA);
    expect(restarted.isLoggedIn, isTrue);
    await restarted.dispose();
  });
}
