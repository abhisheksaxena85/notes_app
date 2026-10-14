import 'package:dio/dio.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/api/api_endpoints.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/network/dto/request/login/login_request_dto.dart';
import 'package:notes_app/data/network/dto/request/profile/profile_request_dto.dart';
import 'package:notes_app/data/network/dto/request/register/register_request_dto.dart';

class ApiClient {
  final Dio _dio = getIt<DioClient>().dio;

  Future<Response> login(LoginRequestDto requestDto) async {
    return _dio.post(ApiEndpoints.LOGIN, data: requestDto.toJson());
  }

  Future<Response> register(RegisterRequestDto requestDto) async {
    return _dio.post(ApiEndpoints.CREATE_USER, data: requestDto.toJson());
  }

  Future<Response> getAllNotes(int id) async {
    return _dio.get(ApiEndpoints.GET_ALL_NOTES, queryParameters: {'id': 1});
  }

  Future<Response> getUserDetails(ProfileRequestDto requestDto) async {
    return _dio.get(
      ApiEndpoints.USER_DETAILS,
      queryParameters: requestDto.toJson(),
    );
  }
}
