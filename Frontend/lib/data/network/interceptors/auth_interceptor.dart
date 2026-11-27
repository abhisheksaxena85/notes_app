import 'dart:async';

import 'package:dio/dio.dart';
import 'package:notes_app/data/local/secure_storage/token_store.dart';
import 'package:notes_app/data/network/api/api_endpoints.dart';

/// SEC-02: sends `Authorization: Bearer <token>` and reports a rejected
/// session.
///
/// [onUnauthorized] runs when the server answers 401 to a request that
/// carried the current session's token (or no token, for a session from
/// before SEC-02). It is not awaited: signing out waits for the running sync
/// pass, which may be the very request that failed. It never runs for:
/// - no response at all (offline, timeout): that is not a 401;
/// - login/signup: there 401 means wrong credentials;
/// - a request sent with an older token, e.g. one still in flight when the
///   user signed in again.
class AuthInterceptor extends Interceptor {
  final TokenStore tokenStore;
  final FutureOr<void> Function()? onUnauthorized;

  /// The token a request was sent with, kept in [RequestOptions.extra].
  static const sentTokenKey = 'daymark.sentToken';

  AuthInterceptor({required this.tokenStore, this.onUnauthorized});

  static bool isCredentialRoute(RequestOptions options) {
    final path = options.uri.path;
    return path.endsWith(ApiEndpoints.LOGIN) || path.endsWith(ApiEndpoints.CREATE_USER);
  }

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!isCredentialRoute(options)) {
      final token = await tokenStore.accessToken();
      options.extra[sentTokenKey] = token;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.type == DioExceptionType.badResponse &&
        err.response?.statusCode == 401 &&
        !isCredentialRoute(options) &&
        options.extra.containsKey(sentTokenKey)) {
      final current = await tokenStore.accessToken();
      if (options.extra[sentTokenKey] == current) {
        unawaited(Future.sync(() => onUnauthorized?.call()));
      }
    }
    handler.next(err);
  }
}
