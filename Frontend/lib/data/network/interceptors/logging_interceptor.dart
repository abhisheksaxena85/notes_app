import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Keys whose values must never be written to logs (compared case-insensitively).
const Set<String> sensitiveLogKeys = {
  'password',
  'oldpassword',
  'newpassword',
  'confirmpassword',
  'accesstoken',
  'refreshtoken',
  'token',
  'authorization',
};

/// Maximum number of characters of a body that is printed.
const int maxLoggedBodyLength = 1024;

const String redactedValue = '***';

/// Returns a copy of [data] with the values of [sensitiveLogKeys] replaced by
/// `***`. Maps and lists are handled recursively; JSON strings are decoded
/// first so that raw JSON bodies are redacted too.
Object? redactSensitive(Object? data) {
  if (data is Map) {
    return data.map((key, value) {
      final isSensitive = sensitiveLogKeys.contains(
        key.toString().toLowerCase(),
      );
      return MapEntry(key, isSensitive ? redactedValue : redactSensitive(value));
    });
  }
  if (data is List) {
    return data.map(redactSensitive).toList();
  }
  if (data is String) {
    final trimmed = data.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        return redactSensitive(jsonDecode(data));
      } on FormatException {
        return data;
      }
    }
  }
  return data;
}

/// Redacts [data] and cuts the result to [maxLength] characters.
String formatBodyForLog(Object? data, {int maxLength = maxLoggedBodyLength}) {
  if (data == null) return '';
  if (data is FormData) return '<form-data>';
  final text = redactSensitive(data).toString();
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}… (${text.length} chars)';
}

/// Debug-only HTTP logger. [DioClient] only installs it when [kDebugMode] is
/// true, so release builds never print request or response bodies.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint(
      '⇨ ${options.method} ${options.uri}\n${formatBodyForLog(options.data)}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '⇦ ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri}\n${formatBodyForLog(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    debugPrint(
      '✖ ${err.requestOptions.method} ${err.requestOptions.uri} -> '
      '${status ?? err.type.name}: ${err.message ?? ''}\n'
      '${formatBodyForLog(err.response?.data)}',
    );
    handler.next(err);
  }
}
