import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/register/register_request_dto.dart';
import 'package:notes_app/data/network/dto/response/register/register_response_dto.dart';

import '../../../di/dependency_injection.dart';

class RegisterRepo {
  final client = getIt<ApiClient>();

  /// Throws a `DioException` for any non-2xx status (e.g. 409 for an email
  /// that is already registered); callers turn it into a message with
  /// `userMessage`.
  Future<RegisterResponseDto> register(RegisterRequestDto requestDto) async {
    final response = await client.register(requestDto);
    return RegisterResponseDto.fromJson(response.data);
  }
}
