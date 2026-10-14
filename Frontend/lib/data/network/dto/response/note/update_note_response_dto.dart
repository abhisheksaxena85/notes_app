import 'package:json_annotation/json_annotation.dart';

part 'update_note_response_dto.g.dart';

@JsonSerializable()
class UpdateNoteResponseDto {
  @JsonKey(name: "success")
  bool? success;
  @JsonKey(name: "message")
  String? message;
  @JsonKey(name: "data")
  UpdateNoteData? data;

  UpdateNoteResponseDto({this.success, this.message, this.data});

  factory UpdateNoteResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateNoteResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateNoteResponseDtoToJson(this);
}

@JsonSerializable()
class UpdateNoteData {
  @JsonKey(name: "noteId")
  int? noteId;
  @JsonKey(name: "title")
  String? title;
  @JsonKey(name: "content")
  String? content;
  @JsonKey(name: "category")
  String? category;
  @JsonKey(name: "updateAt")
  String? updateAt;
  @JsonKey(name: "createdAt")
  String? createdAt;
  @JsonKey(name: "pinned")
  bool? pinned;

  UpdateNoteData({
    this.noteId,
    this.title,
    this.content,
    this.category,
    this.updateAt,
    this.createdAt,
    this.pinned,
  });

  factory UpdateNoteData.fromJson(Map<String, dynamic> json) =>
      _$UpdateNoteDataFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateNoteDataToJson(this);
}
