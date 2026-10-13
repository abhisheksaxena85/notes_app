import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();

  // Request interceptor to log the request
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('⇨ ${options.method} ${options.uri}\n${options.data}');
    handler.next(options);
  }

  // Response interceptor to log the response
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '⇦ ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}\n${response.data}',
    );
    handler.next(response);
  }

  // Error interceptor to log the error
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '✖ ${err.requestOptions.method} ${err.requestOptions.uri} -> ${err.message}, ${err.stackTrace}',
    );
    handler.next(err);
  }
}
