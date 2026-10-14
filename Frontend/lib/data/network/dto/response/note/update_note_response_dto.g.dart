// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_note_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateNoteResponseDto _$UpdateNoteResponseDtoFromJson(
        Map<String, dynamic> json) =>
    UpdateNoteResponseDto(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : UpdateNoteData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UpdateNoteResponseDtoToJson(
        UpdateNoteResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

UpdateNoteData _$UpdateNoteDataFromJson(Map<String, dynamic> json) =>
    UpdateNoteData(
      noteId: (json['noteId'] as num?)?.toInt(),
      title: json['title'] as String?,
      content: json['content'] as String?,
      category: json['category'] as String?,
      updateAt: (json['updateAt'] ?? json['updatedAt']) as String?,
      createdAt: json['createdAt'] as String?,
      pinned: json['pinned'] as bool?,
    );

Map<String, dynamic> _$UpdateNoteDataToJson(UpdateNoteData instance) =>
    <String, dynamic>{
      'noteId': instance.noteId,
      'title': instance.title,
      'content': instance.content,
      'category': instance.category,
      'updateAt': instance.updateAt,
      'createdAt': instance.createdAt,
      'pinned': instance.pinned,
    };
