import 'dart:io';

import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/register/register_request_dto.dart';
import 'package:notes_app/data/network/dto/response/register/register_response_dto.dart';

import '../../../di/dependency_injection.dart';

class RegisterRepo {
  final client = getIt<ApiClient>();

  Future<RegisterResponseDto> register(RegisterRequestDto requestDto) async {
    try {
      var response = await client.register(requestDto);
      if (response.statusCode == 200) {
        return RegisterResponseDto.fromJson(response.data);
      } else {
        throw HttpException((response.statusCode ?? 500).toString());
      }
    } catch (e) {
      throw Exception("Failed to register user!");
    }
  }
}
