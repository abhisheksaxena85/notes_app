import 'package:json_annotation/json_annotation.dart';

part 'delete_note_response_dto.g.dart';

@JsonSerializable()
class DeleteNoteResponseDto {
  @JsonKey(name: "success")
  bool? success;
  @JsonKey(name: "message")
  String? message;
  @JsonKey(name: "data")
  DeleteNoteData? data;

  DeleteNoteResponseDto({this.success, this.message, this.data});

  factory DeleteNoteResponseDto.fromJson(Map<String, dynamic> json) =>
      _$DeleteNoteResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteNoteResponseDtoToJson(this);
}

@JsonSerializable()
class DeleteNoteData {
  @JsonKey(name: "noteId")
  int? noteId;
  @JsonKey(name: "title")
  String? title;
  @JsonKey(name: "content")
  String? content;
  @JsonKey(name: "category")
  String? category;
  @JsonKey(name: "createdAt")
  String? createdAt;
  @JsonKey(name: "updatedAt")
  String? updatedAt;
  @JsonKey(name: "pinned")
  bool? pinned;

  DeleteNoteData({
    this.noteId,
    this.title,
    this.content,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.pinned,
  });

  factory DeleteNoteData.fromJson(Map<String, dynamic> json) =>
      _$DeleteNoteDataFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteNoteDataToJson(this);
}
