import 'dart:io';

import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/profile/profile_request_dto.dart';
import 'package:notes_app/data/network/dto/response/profile/profile_response_dto.dart';

class ProfileRepo {
  final client = getIt<ApiClient>();

  Future<ProfileResponseDto> getUserDetails(
      ProfileRequestDto requestDto) async {
    try {
      var response = await client.getUserDetails(requestDto);
      if (response.statusCode == 200) {
        return ProfileResponseDto.fromJson(response.data);
      } else {
        throw HttpException((response.statusCode ?? 500).toString());
      }
    } catch (e) {
      throw Exception("Failed to get user details!");
    }
  }
}
