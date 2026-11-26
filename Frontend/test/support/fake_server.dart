import 'dart:async';

import 'package:dio/dio.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/note/update_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/update_task_request_dto.dart';

/// An in-memory stand-in for the backend, for sync tests.
///
/// Creates behave like the real server (FE-03): a repeat with a known
/// clientId returns the existing id instead of inserting. Failures can be
/// injected per call with [onRequest], and [gate] holds create responses until
/// it completes so concurrent syncs overlap.
class FakeServer extends ApiClient {
  FakeServer() : super(dioClient: DioClient(Dio()));

  final Map<int, Map<String, dynamic>> notes = {};
  final Map<int, Map<String, dynamic>> tasks = {};
  final Map<int, Map<String, dynamic>> reminders = {};

  /// Every request made, in order, e.g. `createNote`, `getAllTasks`.
  final List<String> calls = [];

  /// Called before a request is handled: throw to make it fail, or return
  /// [FakeServer.loseResponse] to apply the change and then fail as if the
  /// response was lost on the way back.
  Object? Function(String call, Object? request)? onRequest;

  /// Create responses wait for this when set.
  Future<void>? gate;

  int _nextId = 1000;

  static const loseResponse = Object();

  int count(String call) => calls.where((c) => c == call).length;

  static DioException status(int code, [String message = 'Refused']) {
    final options = RequestOptions(path: '/fake');
    return DioException.badResponse(
      statusCode: code,
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: code,
        data: {'success': false, 'message': message, 'data': null},
      ),
    );
  }

  static DioException offline() => DioException.connectionError(
        requestOptions: RequestOptions(path: '/fake'),
        reason: 'offline',
      );

  static DioException timeout() => DioException.receiveTimeout(
        timeout: const Duration(seconds: 10),
        requestOptions: RequestOptions(path: '/fake'),
      );

  Response _ok(Object? data, {int code = 200}) => Response(
        requestOptions: RequestOptions(path: '/fake'),
        statusCode: code,
        data: {'success': true, 'message': 'ok', 'data': data},
      );

  /// Runs [apply] (which may throw, e.g. a 404) unless [onRequest] makes the
  /// call fail first.
  Future<Response> _handle(String call, Object? request, Response Function() apply) async {
    calls.add(call);
    final verdict = onRequest?.call(call, request);
    final response = apply();
    if (identical(verdict, loseResponse)) throw timeout();
    return response;
  }

  Future<Response> _create(
    String call,
    Map<int, Map<String, dynamic>> table,
    String idKey,
    Map<String, dynamic> body, {
    int createdCode = 200,
  }) async {
    calls.add(call);
    final verdict = onRequest?.call(call, body);
    final gate = this.gate;
    if (gate != null) await gate;
    final clientId = body['clientId'] as String?;
    final userId = body['userId'];
    if (clientId != null) {
      for (final row in table.values) {
        if (row['clientId'] == clientId && row['userId'] == userId) {
          return _ok({idKey: row[idKey]});
        }
      }
    }
    final id = _nextId++;
    table[id] = {...body, idKey: id};
    if (identical(verdict, loseResponse)) throw timeout();
    return _ok({idKey: id}, code: createdCode);
  }

  @override
  Future<Response> createNote(CreateNoteRequestDto requestDto) =>
      _create('createNote', notes, 'noteId', requestDto.toJson());

  @override
  Future<Response> createTask(CreateTaskRequestDto requestDto) =>
      _create('createTask', tasks, 'taskId', requestDto.toJson(), createdCode: 201);

  @override
  Future<Response> createReminder(CreateReminderRequestDto requestDto) =>
      _create('createReminder', reminders, 'reminderId', requestDto.toJson(),
          createdCode: 201);

  @override
  Future<Response> getAllNotes(int id) => _handle('getAllNotes', id,
      () => _ok([for (final n in notes.values) if (n['userId'] == id) n]));

  @override
  Future<Response> getAllTasks(int userId) => _handle('getAllTasks', userId,
      () => _ok([for (final t in tasks.values) if (t['userId'] == userId) t]));

  @override
  Future<Response> getAllReminders(int userId) => _handle('getAllReminders', userId,
      () => _ok([for (final r in reminders.values) if (r['userId'] == userId) r]));

  /// Applies [changes] to an existing row, or answers 404 like the backend.
  Future<Response> _change(
    String call,
    Map<int, Map<String, dynamic>> table,
    int id,
    Map<String, dynamic> changes,
  ) =>
      _handle(call, {'id': id, ...changes}, () {
        final row = table[id];
        if (row == null) throw status(404, 'Not found');
        row.addAll({for (final e in changes.entries) if (e.value != null) e.key: e.value});
        return _ok(row);
      });

  Future<Response> _remove(String call, Map<int, Map<String, dynamic>> table, int id) =>
      _handle(call, {'id': id}, () {
        if (table.remove(id) == null) throw status(404, 'Not found');
        return _ok(true);
      });

  @override
  Future<Response> updateNote(UpdateNoteRequestDto requestDto) {
    final body = requestDto.toJson()..remove('noteId');
    return _change('updateNote', notes, requestDto.noteId!, body);
  }

  @override
  Future<Response> togglePin(int noteId) => throw StateError('togglePin is not replay-safe');

  @override
  Future<Response> deleteNote(int id) => _remove('deleteNote', notes, id);

  @override
  Future<Response> updateTask(UpdateTaskRequestDto requestDto) {
    // The backend DTO's primitive isCompleted makes a body without it a 400.
    if (requestDto.isCompleted == null) {
      calls.add('updateTask');
      throw status(400, 'Malformed or missing request body');
    }
    final body = requestDto.toJson()..remove('taskId');
    return _change('updateTask', tasks, requestDto.taskId, body);
  }

  @override
  Future<Response> toggleTaskStatus(int taskId, {String? status}) => _change(
        'toggleTaskStatus',
        tasks,
        taskId,
        {'status': status, 'isCompleted': status == 'COMPLETED'},
      );

  @override
  Future<Response> deleteTask(int taskId) => _remove('deleteTask', tasks, taskId);

  @override
  Future<Response> updateReminder(UpdateReminderRequestDto requestDto) {
    final body = requestDto.toJson()..remove('reminderId');
    return _change('updateReminder', reminders, requestDto.reminderId, body);
  }

  @override
  Future<Response> updateReminderStatus(int reminderId, {String? status}) =>
      _change('updateReminderStatus', reminders, reminderId, {'status': status});

  @override
  Future<Response> deleteReminder(int reminderId) =>
      _remove('deleteReminder', reminders, reminderId);
}
