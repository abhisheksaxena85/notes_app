import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:notes_app/data/local/secure_storage/token_store.dart';
import 'package:notes_app/data/network/config/api_config.dart';
import 'package:notes_app/data/network/interceptors/auth_interceptor.dart';
import 'package:notes_app/data/network/interceptors/logging_interceptor.dart';
import 'package:notes_app/data/network/interceptors/retry_interceptor.dart';

class DioClient {
  final Dio dio;
  DioClient(this.dio);

  /// [tokenStore] supplies the bearer token (SEC-02). [onUnauthorized] runs
  /// once per rejected session (see [AuthInterceptor]); the notification
  /// background isolate passes none, it can't sign the user out.
  factory DioClient.create({
    required TokenStore tokenStore,
    FutureOr<void> Function()? onUnauthorized,
    String? baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.baseUrl,
        sendTimeout: const Duration(seconds: 10),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenStore: tokenStore, onUnauthorized: onUnauthorized),
      // Bodies can contain passwords and note text: never log them in release.
      // Headers (with the bearer token) are never logged.
      if (kDebugMode) LoggingInterceptor(),
      RetryInterceptor(dio),
    ]);

    return DioClient(dio);
  }
}
