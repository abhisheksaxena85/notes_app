import 'package:get_it/get_it.dart';
import 'package:notes_app/data/local/database/app_database.dart';
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
import 'package:notes_app/utils/services/notification_service.dart';

var getIt = GetIt.instance;

Future<void> configureDependencies() async {
  /// Dio Client
  getIt.registerLazySingleton<DioClient>(() => DioClient.create());

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
    ),
  );
}
