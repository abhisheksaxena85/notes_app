import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';

/// A user-facing view of any error thrown by a repository or API call.
///
/// The backend returns real HTTP status codes with an `ApiResponse` body
/// (`success`, `message`, `data`). Dio throws a [DioException] for every
/// non-2xx status, so callers catch that and turn it into a short message here
/// instead of showing raw exception text.
class ApiError {
  final int? statusCode;
  final String message;

  const ApiError({required this.message, this.statusCode});

  static const String genericMessage = 'Something went wrong. Please try again.';
  static const String timeoutMessage =
      'The server took too long to respond. Please try again.';
  static const String offlineMessage =
      'No internet connection. Please check your network and try again.';
  static const String serverMessage =
      'Something went wrong on our side. Please try again later.';

  /// Longest server message that is shown as-is; anything longer is treated
  /// as an unexpected payload and replaced by a default.
  static const int _maxServerMessageLength = 200;

  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;

  factory ApiError.from(Object error) {
    if (error is ApiError) return error;
    if (error is DioException) return _fromDio(error);
    if (error is SocketException) {
      return const ApiError(message: offlineMessage);
    }
    log('Unexpected error: $error');
    return const ApiError(message: genericMessage);
  }

  static ApiError _fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiError(message: timeoutMessage);
      case DioExceptionType.connectionError:
        return const ApiError(message: offlineMessage);
      case DioExceptionType.cancel:
        return const ApiError(message: 'The request was cancelled.');
      case DioExceptionType.badCertificate:
        return const ApiError(message: 'A secure connection could not be made.');
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const ApiError(message: offlineMessage);
        }
        log('Unknown network error: ${error.message}');
        return const ApiError(message: genericMessage);
    }
  }

  static ApiError _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    if (status == null) return const ApiError(message: genericMessage);

    // 5xx text is never shown: it is either our generic message or a proxy page.
    if (status >= 500) {
      return ApiError(statusCode: status, message: serverMessage);
    }

    final serverText = serverMessageOf(response?.data);
    return ApiError(
      statusCode: status,
      message: serverText ?? _defaultFor(status),
    );
  }

  /// The `message` field of an `ApiResponse` body, if it is a short string.
  static String? serverMessageOf(Object? body) {
    if (body is! Map) return null;
    final message = body['message'];
    if (message is! String) return null;
    final trimmed = message.trim();
    if (trimmed.isEmpty || trimmed.length > _maxServerMessageLength) {
      return null;
    }
    return trimmed;
  }

  static String _defaultFor(int status) {
    switch (status) {
      case 400:
        return 'Please check your input and try again.';
      case 401:
        return 'Please log in again.';
      case 403:
        return "You don't have permission to do that.";
      case 404:
        return "We couldn't find what you were looking for.";
      case 409:
        return 'This conflicts with existing data.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return genericMessage;
    }
  }

  @override
  String toString() => message;
}

/// Short, friendly text for [error], safe to show in a snackbar.
String userMessage(Object error) => ApiError.from(error).message;
