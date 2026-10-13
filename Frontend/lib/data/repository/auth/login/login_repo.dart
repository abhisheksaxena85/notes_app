import 'dart:io';

import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/login/login_request_dto.dart';
import 'package:notes_app/data/network/dto/response/login/login_response_dto.dart';

import '../../../di/dependency_injection.dart';

class LoginRepo {
  final client = getIt<ApiClient>();

  Future<LoginResponseDto> login(LoginRequestDto requestDto) async {
    try {
      var response = await client.login(requestDto);
      if (response.statusCode == 200) {
        return LoginResponseDto.fromJson(response.data);
      } else {
        throw HttpException((response.statusCode ?? 500).toString());
      }
    } catch (e) {
      throw Exception("Failed to login user!");
    }
  }
}
