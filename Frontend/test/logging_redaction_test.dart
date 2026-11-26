import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/network/interceptors/logging_interceptor.dart';

void main() {
  group('redactSensitive', () {
    test('masks password fields and keeps the rest', () {
      final result = redactSensitive({
        'email': 'a@b.com',
        'password': 'hunter22',
      }) as Map;

      expect(result['password'], '***');
      expect(result['email'], 'a@b.com');
    });

    test('masks change-password and token keys case-insensitively', () {
      final result = redactSensitive({
        'userId': 7,
        'oldPassword': 'old-secret',
        'NewPassword': 'new-secret',
        'accessToken': 'tok',
        'Authorization': 'Bearer abc',
      }) as Map;

      expect(result['userId'], 7);
      expect(result['oldPassword'], '***');
      expect(result['NewPassword'], '***');
      expect(result['accessToken'], '***');
      expect(result['Authorization'], '***');
    });

    test('redacts nested maps, lists and raw JSON strings', () {
      final nested = redactSensitive({
        'data': [
          {'password': 'x'},
        ],
      }) as Map;
      expect(((nested['data'] as List).first as Map)['password'], '***');

      final fromJson = redactSensitive('{"password":"x","name":"n"}') as Map;
      expect(fromJson['password'], '***');
      expect(fromJson['name'], 'n');
    });
  });

  group('formatBodyForLog', () {
    test('never contains the plaintext password', () {
      final text = formatBodyForLog({'email': 'a@b.com', 'password': 'p4ss'});
      expect(text, isNot(contains('p4ss')));
      expect(text, contains('***'));
    });

    test('truncates large bodies', () {
      final text = formatBodyForLog('x' * 5000, maxLength: 100);
      expect(text.length, lessThan(200));
      expect(text, contains('5000 chars'));
    });

    test('returns empty string for null', () {
      expect(formatBodyForLog(null), '');
    });
  });
}
