// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_note_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateNoteRequestDto _$UpdateNoteRequestDtoFromJson(
        Map<String, dynamic> json) =>
    UpdateNoteRequestDto(
      noteId: (json['noteId'] as num?)?.toInt(),
      title: json['title'] as String?,
      content: json['content'] as String?,
      category: json['category'] as String?,
      pinned: json['pinned'] as bool?,
    );

Map<String, dynamic> _$UpdateNoteRequestDtoToJson(
        UpdateNoteRequestDto instance) =>
    <String, dynamic>{
      'noteId': instance.noteId,
      'title': instance.title,
      'content': instance.content,
      'category': instance.category,
      'pinned': instance.pinned,
    };
