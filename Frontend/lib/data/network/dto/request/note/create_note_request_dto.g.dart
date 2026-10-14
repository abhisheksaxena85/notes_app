// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_note_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateNoteRequestDto _$CreateNoteRequestDtoFromJson(
        Map<String, dynamic> json) =>
    CreateNoteRequestDto(
      userId: (json['userId'] as num?)?.toInt(),
      title: json['title'] as String?,
      content: json['content'] as String?,
      category: json['category'] as String?,
      pinned: json['pinned'] as bool?,
    );

Map<String, dynamic> _$CreateNoteRequestDtoToJson(
        CreateNoteRequestDto instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'title': instance.title,
      'content': instance.content,
      'category': instance.category,
      'pinned': instance.pinned,
    };
