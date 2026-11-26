import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// How the sync loop should react to a failed upload.
enum SyncErrorKind {
  /// No response, timeout, 5xx, 408 or 429: the same request may work later.
  /// Stop this entity's queue and retry with backoff.
  transient,

  /// The server answered and refused the item (other 4xx, or `success:false`
  /// with a 2xx). Retrying the same payload will fail again, so mark the item
  /// failed and move on to the next one.
  permanent,
}

/// Thrown by the sync code when the server answers with a status outside
/// 200-299 without Dio throwing (fake clients, custom `validateStatus`).
class SyncHttpException implements Exception {
  final int? statusCode;
  final String? message;

  const SyncHttpException(this.statusCode, [this.message]);

  @override
  String toString() => 'HTTP ${statusCode ?? 'error'}${message == null ? '' : ': $message'}';
}

/// Thrown when the server answers 2xx but with `success:false` or no id.
class SyncRejectedException implements Exception {
  final String message;

  const SyncRejectedException(this.message);

  @override
  String toString() => message;
}

SyncErrorKind classifyStatus(int? statusCode) {
  if (statusCode == null) return SyncErrorKind.transient;
  if (statusCode == 408 || statusCode == 429) return SyncErrorKind.transient;
  if (statusCode >= 500) return SyncErrorKind.transient;
  if (statusCode >= 400) return SyncErrorKind.permanent;
  return SyncErrorKind.transient;
}

SyncErrorKind classifySyncError(Object error) {
  if (error is SyncRejectedException) return SyncErrorKind.permanent;
  if (error is SyncHttpException) return classifyStatus(error.statusCode);
  if (error is DioException) {
    if (error.type == DioExceptionType.badResponse) {
      return classifyStatus(error.response?.statusCode);
    }
    // Timeouts, connection errors, cancellations, unknown socket errors.
    return SyncErrorKind.transient;
  }
  if (error is SocketException || error is TimeoutException) {
    return SyncErrorKind.transient;
  }
  // A queued payload or a response we cannot parse will not fix itself.
  if (error is FormatException || error is TypeError || error is ArgumentError) {
    return SyncErrorKind.permanent;
  }
  return SyncErrorKind.transient;
}

/// Throws [SyncHttpException] unless [response] has a 2xx status.
void ensureSuccessStatus(Response response) {
  final status = response.statusCode;
  if (status == null || status < 200 || status >= 300) {
    final body = response.data;
    final message = body is Map && body['message'] is String ? body['message'] as String : null;
    throw SyncHttpException(status, message);
  }
}

/// Short text for a failed item, safe to store and show (no payload data).
String describeSyncError(Object error) {
  if (error is SyncRejectedException) return error.message;
  if (error is SyncHttpException) {
    return error.message ?? 'The server refused the change (HTTP ${error.statusCode}).';
  }
  if (error is DioException) {
    final body = error.response?.data;
    if (body is Map && body['message'] is String) {
      final message = (body['message'] as String).trim();
      if (message.isNotEmpty && message.length <= 200) return message;
    }
    final status = error.response?.statusCode;
    if (status != null) return 'The server refused the change (HTTP $status).';
    return 'Network error';
  }
  if (error is FormatException) return 'The saved change is unreadable.';
  return 'Could not sync this item.';
}
