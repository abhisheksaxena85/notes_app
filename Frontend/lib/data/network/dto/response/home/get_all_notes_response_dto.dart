import 'package:json_annotation/json_annotation.dart';

part 'get_all_notes_response_dto.g.dart';

@JsonSerializable()
class GetAllNotesResponseDto {
  @JsonKey(name: "success")
  bool? success;
  @JsonKey(name: "message")
  String? message;
  @JsonKey(name: "data")
  List<NoteItem>? data;

  GetAllNotesResponseDto({this.success, this.message, this.data});

  factory GetAllNotesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GetAllNotesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GetAllNotesResponseDtoToJson(this);
}

@JsonSerializable()
class NoteItem {
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

  NoteItem({
    this.noteId,
    this.title,
    this.content,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.pinned,
  });

  factory NoteItem.fromJson(Map<String, dynamic> json) =>
      _$NoteItemFromJson(json);

  Map<String, dynamic> toJson() => _$NoteItemToJson(this);
}
