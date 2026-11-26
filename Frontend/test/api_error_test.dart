import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/utils/res/api_error.dart';

DioException badResponse(int status, Object? body) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  group('ApiError.from', () {
    test('shows the server message for a wrong password (401)', () {
      final error = ApiError.from(
        badResponse(401, {'success': false, 'message': 'Invalid email or password'}),
      );
      expect(error.statusCode, 401);
      expect(error.isUnauthorized, isTrue);
      expect(error.message, 'Invalid email or password');
    });

    test('shows the server message for a duplicate email (409)', () {
      final message = userMessage(
        badResponse(409, {'success': false, 'message': 'Email id already used by another user'}),
      );
      expect(message, 'Email id already used by another user');
    });

    test('shows the server message for a missing note (404)', () {
      final error = ApiError.from(
        badResponse(404, {'success': false, 'message': 'Note not found'}),
      );
      expect(error.isNotFound, isTrue);
      expect(error.message, 'Note not found');
    });

    test('falls back to a default when the body has no message', () {
      expect(userMessage(badResponse(404, 'not json')), contains("couldn't find"));
      expect(userMessage(badResponse(400, {'success': false})), contains('check your input'));
    });

    test('never shows 5xx text', () {
      final message = userMessage(
        badResponse(500, {'message': 'SQLException: SELECT * FROM users'}),
      );
      expect(message, ApiError.serverMessage);
      expect(message, isNot(contains('SQL')));
    });

    test('maps timeouts and connection errors to friendly text', () {
      final options = RequestOptions(path: '/x');
      expect(
        userMessage(DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        )),
        ApiError.timeoutMessage,
      );
      expect(
        userMessage(DioException.connectionError(
          requestOptions: options,
          reason: 'refused',
        )),
        ApiError.offlineMessage,
      );
      expect(userMessage(const SocketException('down')), ApiError.offlineMessage);
    });

    test('never exposes raw exception text', () {
      for (final error in <Object>[
        Exception('boom'),
        StateError('bad state'),
        DioException(requestOptions: RequestOptions(path: '/x')),
      ]) {
        final message = userMessage(error);
        expect(message, isNot(contains('Exception')));
        expect(message, isNot(contains('StateError')));
        expect(message, ApiError.genericMessage);
      }
    });

    test('ignores overly long server messages', () {
      final message = userMessage(badResponse(400, {'message': 'x' * 500}));
      expect(message.length, lessThan(100));
    });
  });
}
