// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_details_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteDetailsResponseDto _$NoteDetailsResponseDtoFromJson(
        Map<String, dynamic> json) =>
    NoteDetailsResponseDto(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : NoteDetailsData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NoteDetailsResponseDtoToJson(
        NoteDetailsResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

NoteDetailsData _$NoteDetailsDataFromJson(Map<String, dynamic> json) =>
    NoteDetailsData(
      noteId: (json['noteId'] as num?)?.toInt(),
      title: json['title'] as String?,
      content: json['content'] as String?,
      category: json['category'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: (json['updatedAt'] ?? json['updateAt']) as String?,
      pinned: json['pinned'] as bool?,
    );

Map<String, dynamic> _$NoteDetailsDataToJson(NoteDetailsData instance) =>
    <String, dynamic>{
      'noteId': instance.noteId,
      'title': instance.title,
      'content': instance.content,
      'category': instance.category,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'pinned': instance.pinned,
    };
