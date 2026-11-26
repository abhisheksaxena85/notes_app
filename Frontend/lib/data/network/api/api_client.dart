import 'package:dio/dio.dart';
import 'package:notes_app/data/network/api/api_endpoints.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/network/dto/request/login/login_request_dto.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/note/update_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/profile/profile_request_dto.dart';
import 'package:notes_app/data/network/dto/request/register/register_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/create_task_request_dto.dart';
import 'package:notes_app/data/network/dto/request/task/update_task_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/create_reminder_request_dto.dart';
import 'package:notes_app/data/network/dto/request/reminder/update_reminder_request_dto.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({required DioClient dioClient}) : _dio = dioClient.dio;

  Future<Response> login(LoginRequestDto requestDto) async {
    return _dio.post(ApiEndpoints.LOGIN, data: requestDto.toJson());
  }

  Future<Response> register(RegisterRequestDto requestDto) async {
    return _dio.post(ApiEndpoints.CREATE_USER, data: requestDto.toJson());
  }

  Future<Response> getAllNotes(int id) async {
    return _dio.get(ApiEndpoints.GET_ALL_NOTES, queryParameters: {'id': id});
  }

  Future<Response> getUserDetails(ProfileRequestDto requestDto) async {
    return _dio.get(
      ApiEndpoints.USER_DETAILS,
      queryParameters: requestDto.toJson(),
    );
  }

  Future<Response> createNote(CreateNoteRequestDto requestDto) async {
    return _dio.post(ApiEndpoints.CREATE_NOTE, data: requestDto.toJson());
  }

  Future<Response> updateNote(UpdateNoteRequestDto requestDto) async {
    return _dio.put(ApiEndpoints.UPDATE_NOTE, data: requestDto.toJson());
  }

  Future<Response> getNoteDetails(int id) async {
    return _dio.get(ApiEndpoints.GET_NOTE_DETAILS, queryParameters: {'id': id});
  }

  Future<Response> deleteNote(int id) async {
    return _dio.delete(ApiEndpoints.DELETE_NOTE, queryParameters: {'id': id}, data: id);
  }

  Future<Response> togglePin(int noteId) async {
    return _dio.put(ApiEndpoints.TOGGLE_PIN, queryParameters: {'id': noteId});
  }

  /// [tz] is an IANA zone name (e.g. `Asia/Kolkata`) used to bucket
  /// timestamps into days; the server uses UTC without it.
  Future<Response> getCalendarSummary(
    int userId,
    int year,
    int month, {
    String? tz,
  }) async {
    return _dio.get(
      ApiEndpoints.CALENDAR_SUMMARY,
      queryParameters: {
        'userId': userId,
        'year': year,
        'month': month,
        'tz': ?tz,
      },
    );
  }

  /// See [getCalendarSummary] for [tz].
  Future<Response> getNotesByDate(int userId, String date, {String? tz}) async {
    return _dio.get(
      ApiEndpoints.GET_NOTES_BY_DATE,
      queryParameters: {'userId': userId, 'date': date, 'tz': ?tz},
    );
  }

  Future<Response> searchNotes(int userId, String query) async {
    return _dio.get(
      ApiEndpoints.SEARCH_NOTES,
      queryParameters: {'userId': userId, 'query': query},
    );
  }

  Future<Response> exportNotes(int userId) async {
    return _dio.get(
      ApiEndpoints.EXPORT_NOTES,
      queryParameters: {'userId': userId},
    );
  }

  Future<Response> updateUser(Map<String, dynamic> data) async {
    return _dio.put(ApiEndpoints.UPDATE_USER, data: data);
  }

  Future<Response> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    return _dio.put(
      ApiEndpoints.CHANGE_PASSWORD,
      data: {
        'userId': userId,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<Response> deleteUser(int userId) async {
    return _dio.delete(
      ApiEndpoints.DELETE_USER,
      queryParameters: {'id': userId},
    );
  }

  // Tasks
  Future<Response> createTask(CreateTaskRequestDto requestDto) async {
    return _dio.post(ApiEndpoints.CREATE_TASK, data: requestDto.toJson());
  }

  Future<Response> getAllTasks(int userId) async {
    return _dio.get(ApiEndpoints.GET_ALL_TASKS, queryParameters: {'userId': userId});
  }

  Future<Response> getTasksByDate(int userId, String date) async {
    return _dio.get(
      ApiEndpoints.GET_TASKS_BY_DATE,
      queryParameters: {'userId': userId, 'date': date},
    );
  }

  Future<Response> updateTask(UpdateTaskRequestDto requestDto) async {
    return _dio.put(ApiEndpoints.UPDATE_TASK, data: requestDto.toJson());
  }

  Future<Response> toggleTaskStatus(int taskId, {String? status}) async {
    return _dio.put(
      ApiEndpoints.TOGGLE_TASK_STATUS,
      queryParameters: {
        'taskId': taskId,
        'status': ?status,
      },
    );
  }

  Future<Response> deleteTask(int taskId) async {
    return _dio.delete(
      ApiEndpoints.DELETE_TASK,
      queryParameters: {'taskId': taskId},
    );
  }

  // Reminders
  Future<Response> createReminder(CreateReminderRequestDto requestDto) async {
    return _dio.post(ApiEndpoints.CREATE_REMINDER, data: requestDto.toJson());
  }

  Future<Response> getAllReminders(int userId) async {
    return _dio.get(ApiEndpoints.GET_ALL_REMINDERS, queryParameters: {'userId': userId});
  }

  Future<Response> getRemindersByDate(int userId, String date) async {
    return _dio.get(
      ApiEndpoints.GET_REMINDERS_BY_DATE,
      queryParameters: {'userId': userId, 'date': date},
    );
  }

  Future<Response> updateReminder(UpdateReminderRequestDto requestDto) async {
    return _dio.put(ApiEndpoints.UPDATE_REMINDER, data: requestDto.toJson());
  }

  Future<Response> updateReminderStatus(int reminderId, {String? status}) async {
    return _dio.put(
      ApiEndpoints.UPDATE_REMINDER_STATUS,
      queryParameters: {
        'reminderId': reminderId,
        'status': ?status,
      },
    );
  }

  Future<Response> deleteReminder(int reminderId) async {
    return _dio.delete(
      ApiEndpoints.DELETE_REMINDER,
      queryParameters: {'reminderId': reminderId},
    );
  }
}
