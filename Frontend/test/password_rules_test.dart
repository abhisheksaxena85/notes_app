import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/viewmodel/auth/register/register_viewmodel.dart';

void main() {
  group('RegisterViewmodel.passwordValidationError (matches the server rule)', () {
    test('rejects empty, short and overly long passwords', () {
      expect(RegisterViewmodel.passwordValidationError(''), isNotNull);
      expect(RegisterViewmodel.passwordValidationError('1234567'), contains('at least 8'));
      expect(RegisterViewmodel.passwordValidationError('x' * 73), contains('at most 72'));
    });

    test('accepts 8 to 72 characters, counting spaces', () {
      expect(RegisterViewmodel.passwordValidationError('12345678'), isNull);
      expect(RegisterViewmodel.passwordValidationError(' pass12 '), isNull);
      expect(RegisterViewmodel.passwordValidationError('x' * 72), isNull);
    });
  });
}
