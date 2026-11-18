import 'package:internet_connection_checker/internet_connection_checker.dart';
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
import 'package:notes_app/data/sync/offline_sync_service.dart';

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

  /// Repositories
  getIt.registerLazySingleton<HomeRepo>(
    () => HomeRepo(client: getIt<ApiClient>(), database: getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<NoteRepo>(
    () => NoteRepo(client: getIt<ApiClient>(), database: getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<ProfileRepo>(
    () =>
        ProfileRepo(client: getIt<ApiClient>(), database: getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<TaskRepo>(
    () => TaskRepo(client: getIt<ApiClient>(), database: getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<ReminderRepo>(
    () => ReminderRepo(client: getIt<ApiClient>(), database: getIt<AppDatabase>()),
  );

  /// Background synchronization
  getIt.registerLazySingleton<OfflineSyncService>(
    () => OfflineSyncService(
      noteRepo: getIt<NoteRepo>(),
      taskRepo: getIt<TaskRepo>(),
      reminderRepo: getIt<ReminderRepo>(),
      connectionChecker: InternetConnectionChecker.createInstance(),
    ),
  );
}
