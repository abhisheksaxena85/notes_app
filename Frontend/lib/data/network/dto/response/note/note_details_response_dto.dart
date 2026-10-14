import 'package:json_annotation/json_annotation.dart';

part 'note_details_response_dto.g.dart';

@JsonSerializable()
class NoteDetailsResponseDto {
  @JsonKey(name: "success")
  bool? success;
  @JsonKey(name: "message")
  String? message;
  @JsonKey(name: "data")
  NoteDetailsData? data;

  NoteDetailsResponseDto({this.success, this.message, this.data});

  factory NoteDetailsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$NoteDetailsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NoteDetailsResponseDtoToJson(this);
}

@JsonSerializable()
class NoteDetailsData {
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

  NoteDetailsData({
    this.noteId,
    this.title,
    this.content,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.pinned,
  });

  factory NoteDetailsData.fromJson(Map<String, dynamic> json) =>
      _$NoteDetailsDataFromJson(json);

  Map<String, dynamic> toJson() => _$NoteDetailsDataToJson(this);
}
