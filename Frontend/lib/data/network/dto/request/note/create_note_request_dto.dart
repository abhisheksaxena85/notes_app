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

  /// FE-03: idempotency key, so a retried create can't make a duplicate.
  @JsonKey(name: "clientId", includeIfNull: false)
  String? clientId;

  CreateNoteRequestDto({
    this.userId,
    this.title,
    this.content,
    this.category,
    this.pinned,
    this.tags,
    this.clientId,
  });

  factory CreateNoteRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateNoteRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateNoteRequestDtoToJson(this);
}
