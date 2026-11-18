import 'package:json_annotation/json_annotation.dart';

part 'create_note_request_dto.g.dart';

@JsonSerializable()
class CreateNoteRequestDto {
  @JsonKey(name: "userId")
  int? userId;
  @JsonKey(name: "title")
  String? title;
  @JsonKey(name: "content")
  String? content;
  @JsonKey(name: "category")
  String? category;
  @JsonKey(name: "pinned")
  bool? pinned;
  @JsonKey(name: "tags")
  String? tags;

  CreateNoteRequestDto({
    this.userId,
    this.title,
    this.content,
    this.category,
    this.pinned,
    this.tags,
  });

  factory CreateNoteRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateNoteRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateNoteRequestDtoToJson(this);
}
