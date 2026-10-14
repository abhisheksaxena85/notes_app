// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_note_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteNoteResponseDto _$DeleteNoteResponseDtoFromJson(
        Map<String, dynamic> json) =>
    DeleteNoteResponseDto(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : DeleteNoteData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DeleteNoteResponseDtoToJson(
        DeleteNoteResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

DeleteNoteData _$DeleteNoteDataFromJson(Map<String, dynamic> json) =>
    DeleteNoteData(
      noteId: (json['noteId'] as num?)?.toInt(),
      title: json['title'] as String?,
      content: json['content'] as String?,
      category: json['category'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: (json['updatedAt'] ?? json['updateAt']) as String?,
      pinned: json['pinned'] as bool?,
    );

Map<String, dynamic> _$DeleteNoteDataToJson(DeleteNoteData instance) =>
    <String, dynamic>{
      'noteId': instance.noteId,
      'title': instance.title,
      'content': instance.content,
      'category': instance.category,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'pinned': instance.pinned,
    };
