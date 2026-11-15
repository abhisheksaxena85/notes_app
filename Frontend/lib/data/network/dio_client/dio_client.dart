import 'package:dio/dio.dart';
import 'package:notes_app/data/network/interceptors/auth_interceptor.dart';
import 'package:notes_app/data/network/interceptors/logging_interceptor.dart';
import 'package:notes_app/data/network/interceptors/retry_interceptor.dart';

class DioClient {
  final Dio dio;
  DioClient(this.dio);

  factory DioClient.create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: "https://notesapp-production-d43adec7.up.railway.app",
        sendTimeout: const Duration(seconds: 10),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
      RetryInterceptor(dio),
    ]);

    return DioClient(dio);
  }
}
