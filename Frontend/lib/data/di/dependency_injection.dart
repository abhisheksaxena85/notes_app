import 'package:get_it/get_it.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/secure_storage/token_store.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/repository/home/home_repo.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/repository/profile/profile_repo.dart';
import 'package:notes_app/data/repository/reminder/reminder_repo.dart';
import 'package:notes_app/data/repository/task/task_repo.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/utils/services/connectivity_service.dart';
import 'package:notes_app/utils/services/digest_scheduler.dart';
import 'package:notes_app/utils/services/home_widgets/widget_host.dart';
import 'package:notes_app/utils/services/home_widgets/widget_snapshot_service.dart';
import 'package:notes_app/utils/services/notification_permission_service.dart';
import 'package:notes_app/utils/services/notification_service.dart';
import 'package:notes_app/utils/services/reminder_action_handler.dart';
import 'package:notes_app/utils/services/reminder_scheduler.dart';

var getIt = GetIt.instance;

Future<void> configureDependencies() async {
  /// Access token in secure storage (SEC-02). Written only by SessionService.
  getIt.registerLazySingleton<TokenStore>(() => TokenStore.platform());

  /// Dio Client. A 401 for the current session signs the user out once.
  getIt.registerLazySingleton<DioClient>(
    () => DioClient.create(
      tokenStore: getIt<TokenStore>(),
      onUnauthorized: () => getIt<SessionService>().expire(),
    ),
  );

  /// Api Client
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(dioClient: getIt<DioClient>()),
  );

  /// Shared Preference
  getIt.registerLazySingleton<Preference>(() => Preference());

  /// Local database
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  /// OS notifications (REM-01). A no-op on web, Windows and Linux.
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());

  /// Notification permission, asked in context (REM-02).
  getIt.registerLazySingleton<NotificationPermissionService>(
    () => NotificationPermissionService(
      notifications: getIt<NotificationService>(),
      preference: getIt<Preference>(),
    ),
  );

  /// Connectivity: the only network checker in the app. Started once in
  /// `initialize()` and shared by the sync service and the snackbars.
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService.device(),
    dispose: (service) => service.dispose(),
  );

  /// Background synchronization: the only path from the offline queues to
  /// the server. Repositories ask it to sync after every local write.
  getIt.registerLazySingleton<OfflineSyncService>(
    () => OfflineSyncService(
      client: getIt<ApiClient>(),
      database: getIt<AppDatabase>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  /// Repositories
  getIt.registerLazySingleton<HomeRepo>(
    () => HomeRepo(
      client: getIt<ApiClient>(),
      database: getIt<AppDatabase>(),
      syncService: getIt<OfflineSyncService>(),
    ),
  );
  getIt.registerLazySingleton<NoteRepo>(
    () => NoteRepo(
      client: getIt<ApiClient>(),
      database: getIt<AppDatabase>(),
      syncService: getIt<OfflineSyncService>(),
    ),
  );
  getIt.registerLazySingleton<ProfileRepo>(
    () =>
        ProfileRepo(client: getIt<ApiClient>(), database: getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<TaskRepo>(
    () => TaskRepo(
      client: getIt<ApiClient>(),
      database: getIt<AppDatabase>(),
      syncService: getIt<OfflineSyncService>(),
    ),
  );
  getIt.registerLazySingleton<ReminderRepo>(
    () => ReminderRepo(
      client: getIt<ApiClient>(),
      database: getIt<AppDatabase>(),
      syncService: getIt<OfflineSyncService>(),
    ),
  );

  /// Who is signed in. The only reader and writer of the stored user id.
  getIt.registerLazySingleton<SessionService>(
    () => SessionService(
      preference: getIt<Preference>(),
      database: getIt<AppDatabase>(),
      syncService: getIt<OfflineSyncService>(),
      profileRepo: getIt<ProfileRepo>(),
      tokenStore: getIt<TokenStore>(),
      cancelReminders: () => getIt<ReminderScheduler>().cancelAllReminders(),
      clearWidgets: () => getIt<WidgetSnapshotService>().showLoggedOut(),
    ),
  );

  /// Home-screen widgets (W-01): snapshot of the signed-in user's tasks and
  /// reminders. A no-op on web and desktop.
  getIt.registerLazySingleton<WidgetSnapshotService>(
    () => WidgetSnapshotService(
      database: getIt<AppDatabase>(),
      host: HomeWidgetHost(),
      currentUserId: () => getIt<SessionService>().userId,
    ),
    dispose: (service) => service.dispose(),
  );

  /// Keeps scheduled reminder notifications equal to the database (REM-03).
  getIt.registerLazySingleton<ReminderScheduler>(
    () => ReminderScheduler(
      database: getIt<AppDatabase>(),
      repo: getIt<ReminderRepo>(),
      notifications: getIt<NotificationService>(),
      currentUserId: () => getIt<SessionService>().userId,
    ),
    dispose: (scheduler) => scheduler.dispose(),
  );

  /// Daily reminder and weekly summary notifications (REM-08).
  getIt.registerLazySingleton<DigestScheduler>(
    () => DigestScheduler(
      notifications: getIt<NotificationService>(),
      preference: getIt<Preference>(),
      database: getIt<AppDatabase>(),
      currentUserId: () => getIt<SessionService>().userId,
    ),
  );

  /// Done / Not done / Snooze answers given while the app runs (REM-04). The
  /// background isolate builds its own (notification_background.dart).
  getIt.registerLazySingleton<ReminderActionHandler>(
    () => ReminderActionHandler(
      database: getIt<AppDatabase>(),
      repo: getIt<ReminderRepo>(),
      scheduler: getIt<ReminderScheduler>(),
      currentUserId: () => getIt<SessionService>().userId,
      pushChanges: () => getIt<OfflineSyncService>().requestSync(),
    ),
  );
}
