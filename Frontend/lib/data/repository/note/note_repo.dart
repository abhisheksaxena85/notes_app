import 'dart:io';

import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/note/create_note_request_dto.dart';
import 'package:notes_app/data/network/dto/request/note/update_note_request_dto.dart';
import 'package:notes_app/data/network/dto/response/note/create_note_response_dto.dart';
import 'package:notes_app/data/network/dto/response/note/note_details_response_dto.dart';
import 'package:notes_app/data/network/dto/response/note/update_note_response_dto.dart';

class NoteRepo {
  final client = getIt<ApiClient>();

  Future<CreateNoteResponseDto> createNote(
      CreateNoteRequestDto requestDto) async {
    try {
      var response = await client.createNote(requestDto);
      if (response.statusCode == 200) {
        return CreateNoteResponseDto.fromJson(response.data);
      } else {
        throw HttpException((response.statusCode ?? 500).toString());
      }
    } catch (e) {
      throw Exception("Failed to create note: $e");
    }
  }

  Future<UpdateNoteResponseDto> updateNote(
      UpdateNoteRequestDto requestDto) async {
    try {
      var response = await client.updateNote(requestDto);
      if (response.statusCode == 200) {
        return UpdateNoteResponseDto.fromJson(response.data);
      } else {
        throw HttpException((response.statusCode ?? 500).toString());
      }
    } catch (e) {
      throw Exception("Failed to update note: $e");
    }
  }

  Future<NoteDetailsResponseDto> getNoteDetails(int id) async {
    try {
      var response = await client.getNoteDetails(id);
      if (response.statusCode == 200) {
        return NoteDetailsResponseDto.fromJson(response.data);
      } else {
        throw HttpException((response.statusCode ?? 500).toString());
      }
    } catch (e) {
      throw Exception("Failed to get note details: $e");
    }
  }
}
