import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// SEC-02: the access token from login/signup and when it expires.
class AuthToken {
  final String accessToken;
  final DateTime? expiresAt;

  const AuthToken({required this.accessToken, this.expiresAt});

  /// The token from a login/signup response, or null when the server sent
  /// none (a backend from before SEC-01).
  static AuthToken? fromResponse(String? accessToken, String? expiresAt) {
    if (accessToken == null || accessToken.isEmpty) return null;
    return AuthToken(
      accessToken: accessToken,
      expiresAt: expiresAt == null ? null : DateTime.tryParse(expiresAt),
    );
  }
}

/// The key/value store [TokenStore] writes to. The app uses the platform
/// keystore ([PlatformSecureStore]); tests use an in-memory map.
abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Keychain on iOS, Keystore-encrypted storage on Android.
class PlatformSecureStore implements SecureStore {
  // first_unlock_this_device: the notification background isolate (REM-04)
  // must read the token when "Done" is tapped on a locked iPhone. The default
  // (unlocked) would refuse it. "this_device": never restored to another
  // phone from a backup.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  const PlatformSecureStore();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// SEC-02: where the access token lives. Never SharedPreferences, never logs.
///
/// Written only by `SessionService` (login, logout). Read by `AuthInterceptor`
/// for every request; the first read is cached for the life of this object.
/// The notification background isolate builds its own [TokenStore], so it
/// always reads what the app saved last.
class TokenStore {
  static const accessTokenKey = 'daymark.accessToken';
  static const expiresAtKey = 'daymark.accessTokenExpiresAt';

  final SecureStore _store;

  String? _cached;
  bool _loaded = false;

  TokenStore(this._store);

  TokenStore.platform() : this(const PlatformSecureStore());

  /// The token to send, or null when there is none (signed out, or signed in
  /// before SEC-02).
  Future<String?> accessToken() async {
    if (_loaded) return _cached;
    try {
      _cached = await _store.read(accessTokenKey);
    } catch (error) {
      // A broken keystore must not crash every request; the server answers
      // 401 and the user signs in again.
      log('Could not read the access token: ${error.runtimeType}');
      _cached = null;
    }
    _loaded = true;
    return _cached;
  }

  Future<void> save(AuthToken token) async {
    await _store.write(accessTokenKey, token.accessToken);
    final expiresAt = token.expiresAt;
    if (expiresAt != null) {
      await _store.write(expiresAtKey, expiresAt.toUtc().toIso8601String());
    } else {
      await _store.delete(expiresAtKey);
    }
    _cached = token.accessToken;
    _loaded = true;
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    try {
      await _store.delete(accessTokenKey);
      await _store.delete(expiresAtKey);
    } catch (error) {
      log('Could not delete the access token: ${error.runtimeType}');
    }
  }
}
