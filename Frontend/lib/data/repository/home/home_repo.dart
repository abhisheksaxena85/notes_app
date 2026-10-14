import 'dart:io';

import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';

class HomeRepo {
  final client = getIt<ApiClient>();

  Future<GetAllNotesResponseDto> getAllNotes(int id) async {
    try {
      var response = await client.getAllNotes(id);
      if (response.statusCode == 200) {
        return GetAllNotesResponseDto.fromJson(response.data);
      } else {
        throw HttpException((response.statusCode ?? 500).toString());
      }
    } catch (e) {
      throw Exception("Failed to get notes!");
    }
  }
}
