import 'package:json_annotation/json_annotation.dart';

part 'update_note_request_dto.g.dart';

@JsonSerializable()
class UpdateNoteRequestDto {
  @JsonKey(name: "noteId")
  int? noteId;
  @JsonKey(name: "title")
  String? title;
  @JsonKey(name: "content")
  String? content;
  @JsonKey(name: "category")
  String? category;
  @JsonKey(name: "pinned")
  bool? pinned;

  UpdateNoteRequestDto({
    this.noteId,
    this.title,
    this.content,
    this.category,
    this.pinned,
  });

  factory UpdateNoteRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateNoteRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateNoteRequestDtoToJson(this);
}
