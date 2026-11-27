import 'package:notes_app/data/local/secure_storage/token_store.dart';

/// Secure storage stand-in for tests (the platform plugin isn't available).
class InMemorySecureStore implements SecureStore {
  final Map<String, String> values = {};
  int reads = 0;

  @override
  Future<String?> read(String key) async {
    reads++;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
