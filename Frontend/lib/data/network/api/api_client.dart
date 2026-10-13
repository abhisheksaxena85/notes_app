import 'package:dio/dio.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/api/api_endpoints.dart';
import 'package:notes_app/data/network/dio_client/dio_client.dart';
import 'package:notes_app/data/network/dto/request/login/login_request_dto.dart';

class ApiClient {
  final Dio _dio = getIt<DioClient>().dio;

  Future<Response> login(LoginRequestDto requestDto) async {
    return _dio.post(ApiEndpoints.LOGIN, data: requestDto.toJson());
  }
}
