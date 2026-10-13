import 'package:get_it/get_it.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';

var getIt = GetIt.instance;

Future<void> configureDependencies() async {
  /// Dio Client
  getIt.registerLazySingleton<DioClient>(() => DioClient.create());

  /// Api Client
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());

  /// Shared Preference
  getIt.registerLazySingleton<Preference>(() => Preference());
}
