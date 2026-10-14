// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_note_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateNoteResponseDto _$CreateNoteResponseDtoFromJson(
        Map<String, dynamic> json) =>
    CreateNoteResponseDto(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : CreateNoteData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateNoteResponseDtoToJson(
        CreateNoteResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

CreateNoteData _$CreateNoteDataFromJson(Map<String, dynamic> json) =>
    CreateNoteData(
      noteId: (json['noteId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateNoteDataToJson(CreateNoteData instance) =>
    <String, dynamic>{
      'noteId': instance.noteId,
    };
