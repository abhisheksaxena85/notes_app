// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_all_notes_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAllNotesResponseDto _$GetAllNotesResponseDtoFromJson(
        Map<String, dynamic> json) =>
    GetAllNotesResponseDto(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => NoteItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetAllNotesResponseDtoToJson(
        GetAllNotesResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

NoteItem _$NoteItemFromJson(Map<String, dynamic> json) => NoteItem(
      noteId: (json['noteId'] as num?)?.toInt(),
      title: json['title'] as String?,
      content: json['content'] as String?,
      category: json['category'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      pinned: json['pinned'] as bool?,
    );

Map<String, dynamic> _$NoteItemToJson(NoteItem instance) => <String, dynamic>{
      'noteId': instance.noteId,
      'title': instance.title,
      'content': instance.content,
      'category': instance.category,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'pinned': instance.pinned,
    };
