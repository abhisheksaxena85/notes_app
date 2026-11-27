import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/local/secure_storage/token_store.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/local/shared_preference/preference_keys.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/response/login/login_response_dto.dart';
import 'package:notes_app/data/repository/note/note_repo.dart';
import 'package:notes_app/data/repository/profile/profile_repo.dart';
import 'package:notes_app/data/session/session_service.dart';
import 'package:notes_app/data/sync/offline_sync_service.dart';
import 'package:notes_app/data/sync/sync_error.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_server.dart';
import 'support/in_memory_secure_store.dart';

/// Answers every request with [respond] and records what was sent.
class _FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  FutureOr<ResponseBody> Function(RequestOptions options) respond;

  _FakeAdapter(this.respond);

  static ResponseBody json(int status, Map<String, dynamic> body) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  static ResponseBody ok() => json(200, {'success': true, 'message': 'ok', 'data': []});

  static ResponseBody unauthorized() =>
      json(401, {'success': false, 'message': 'Invalid or expired token', 'data': null});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

const _token = AuthToken(accessToken: 'token-a');

/// SEC-02: bearer token storage, the auth interceptor and 401 handling.
void main() {
  group('AuthInterceptor', () {
    late InMemorySecureStore secure;
    late TokenStore tokens;
    late _FakeAdapter adapter;
    late int unauthorizedCalls;
    late Dio dio;

    setUp(() {
      secure = InMemorySecureStore();
      tokens = TokenStore(secure);
      adapter = _FakeAdapter((_) => _FakeAdapter.ok());
      unauthorizedCalls = 0;
      dio = DioClient.create(
        tokenStore: tokens,
        onUnauthorized: () => unauthorizedCalls++,
        baseUrl: 'https://api.test',
      ).dio
        ..httpClientAdapter = adapter;
    });

    test('sends the stored token as a bearer header', () async {
      await tokens.save(_token);
      await dio.get('/notes/get-all-notes');
      expect(adapter.requests.single.headers['Authorization'], 'Bearer token-a');
    });

    test('sends no header without a token', () async {
      await dio.get('/notes/get-all-notes');
      expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('never sends the token to login or signup', () async {
      await tokens.save(_token);
      await dio.post('/auth/login', data: {'email': 'a@b.c', 'password': 'x'});
      await dio.post('/auth/create-user', data: {});
      for (final request in adapter.requests) {
        expect(request.headers.containsKey('Authorization'), isFalse);
      }
    });

    test('a 401 on a data route reports the session once per request', () async {
      await tokens.save(_token);
      adapter.respond = (_) => _FakeAdapter.unauthorized();
      await expectLater(dio.get('/tasks/get-all-tasks'), throwsA(isA<DioException>()));
      await pumpEventQueue();
      expect(unauthorizedCalls, 1);
    });

    test('a 401 from login is wrong credentials, not an expired session', () async {
      adapter.respond = (_) => _FakeAdapter.unauthorized();
      await expectLater(dio.post('/auth/login', data: {}), throwsA(isA<DioException>()));
      await pumpEventQueue();
      expect(unauthorizedCalls, 0);
    });

    test('being offline or a server error is not a 401', () async {
      await tokens.save(_token);
      adapter.respond = (_) => throw const SocketException('offline');
      await expectLater(dio.get('/tasks/get-all-tasks'), throwsA(isA<DioException>()));
      adapter.respond = (_) => _FakeAdapter.json(500, {'success': false});
      await expectLater(dio.get('/tasks/get-all-tasks'), throwsA(isA<DioException>()));
      adapter.respond = (_) => _FakeAdapter.json(403, {'success': false});
      await expectLater(dio.get('/tasks/get-all-tasks'), throwsA(isA<DioException>()));
      await pumpEventQueue();
      expect(unauthorizedCalls, 0);
    });

    test('a 401 for a request sent with an older token is ignored', () async {
      await tokens.save(_token);
      final release = Completer<void>();
      adapter.respond = (_) async {
        await release.future;
        return _FakeAdapter.unauthorized();
      };
      final inFlight = dio.get('/tasks/get-all-tasks');
      await pumpEventQueue();
      // The user signed in again while the old request was on its way.
      await tokens.save(const AuthToken(accessToken: 'token-b'));
      release.complete();
      await expectLater(inFlight, throwsA(isA<DioException>()));
      await pumpEventQueue();
      expect(unauthorizedCalls, 0);
    });

    test('reads secure storage once, then serves the cached token', () async {
      secure.values[TokenStore.accessTokenKey] = 'saved-before-restart';
      await dio.get('/a');
      await dio.get('/b');
      expect(adapter.requests.map((r) => r.headers['Authorization']),
          everyElement('Bearer saved-before-restart'));
      expect(secure.reads, 1);
    });
  });

  group('SessionService with tokens', () {
    const userA = 1;
    late AppDatabase database;
    late FakeServer server;
    late OfflineSyncService sync;
    late InMemorySecureStore secure;
    late SessionService session;
    late NoteRepo notes;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Preference.init();
      database = AppDatabase.forTesting(NativeDatabase.memory());
      server = FakeServer();
      sync = OfflineSyncService(
        client: server,
        database: database,
        minRetryDelay: const Duration(minutes: 1),
        maxRetryDelay: const Duration(minutes: 8),
      );
      secure = InMemorySecureStore();
      session = SessionService(
        preference: Preference(),
        database: database,
        syncService: sync,
        profileRepo: ProfileRepo(client: server, database: database),
        tokenStore: TokenStore(secure),
      )..restore();
      notes = NoteRepo(client: server, database: database, syncService: sync);
    });

    tearDown(() async {
      await sync.dispose();
      await session.dispose();
      await database.close();
    });

    test('login keeps the token in secure storage, never in SharedPreferences', () async {
      await session.login(userA, token: AuthToken(
        accessToken: 'secret-token',
        expiresAt: DateTime.utc(2030, 1, 1),
      ));

      expect(secure.values[TokenStore.accessTokenKey], 'secret-token');
      expect(secure.values[TokenStore.expiresAtKey], '2030-01-01T00:00:00.000Z');
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        expect(prefs.get(key).toString(), isNot(contains('secret-token')), reason: key);
      }
    });

    test('logout deletes the token', () async {
      await session.login(userA, token: _token);
      await session.logout();
      expect(secure.values, isEmpty);
      expect(await session.tokenStore.accessToken(), isNull);
    });

    test('expire signs out once however many 401s arrive, and keeps local changes', () async {
      final expirations = <void>[];
      session.expirations.listen(expirations.add);
      await session.login(userA, token: _token);
      server.onRequest = (_, _) => throw FakeServer.status(401);
      await notes.enqueueNote(CreateNoteRequestDto(userId: userA, title: 'offline edit', content: 'a'));
      await sync.requestSync();

      final results = await Future.wait([session.expire(), session.expire(), session.expire()]);
      await pumpEventQueue();

      expect(results.where((signedOut) => signedOut), hasLength(1));
      expect(expirations, hasLength(1));
      expect(session.isLoggedIn, isFalse);
      expect(Preference().getInt(PreferenceKeys.USER_ID), isNull);
      expect(secure.values, isEmpty);
      // The 401 didn't fail the queued note, and signing out didn't wipe it.
      expect(await database.countUnsyncedChanges(userA), 1);
      expect(await session.expire(), isFalse);
    });

    test('the queued change uploads after the same user signs in again', () async {
      await session.login(userA, token: _token);
      server.onRequest = (_, _) => throw FakeServer.status(401);
      await notes.enqueueNote(CreateNoteRequestDto(userId: userA, title: 'kept', content: 'a'));
      await sync.requestSync();
      await session.expire();

      server.onRequest = null;
      await session.login(userA, token: const AuthToken(accessToken: 'token-b'));
      await sync.requestSync();

      expect(await database.countUnsyncedChanges(userA), 0);
      expect(server.notes.values.map((n) => n['title']), ['kept']);
    });
  });

  test('a 401 is transient for the sync queue: the item is not failed', () {
    expect(classifyStatus(401), SyncErrorKind.transient);
    expect(classifySyncError(FakeServer.status(401)), SyncErrorKind.transient);
    expect(classifyStatus(403), SyncErrorKind.permanent);
  });

  test('login response carries the token fields', () {
    final dto = LoginResponseDto.fromJson({
      'success': true,
      'message': 'ok',
      'data': {'userId': 4, 'accessToken': 'abc', 'expiresAt': '2026-12-04T10:00:00Z'},
    });
    final token = AuthToken.fromResponse(dto.data?.accessToken, dto.data?.expiresAt)!;
    expect(token.accessToken, 'abc');
    expect(token.expiresAt, DateTime.utc(2026, 12, 4, 10));
    expect(AuthToken.fromResponse(null, null), isNull);
  });
}
