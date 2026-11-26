import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/login/login_request_dto.dart';
import 'package:notes_app/data/network/dto/response/login/login_response_dto.dart';

import '../../../di/dependency_injection.dart';

class LoginRepo {
  final client = getIt<ApiClient>();

  /// Throws a `DioException` for any non-2xx status (e.g. 401 for wrong
  /// credentials); callers turn it into a message with `userMessage`.
  Future<LoginResponseDto> login(LoginRequestDto requestDto) async {
    final response = await client.login(requestDto);
    return LoginResponseDto.fromJson(response.data);
  }
}
