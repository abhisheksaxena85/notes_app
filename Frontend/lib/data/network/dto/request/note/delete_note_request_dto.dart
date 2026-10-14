import 'package:json_annotation/json_annotation.dart';

part 'delete_note_request_dto.g.dart';

@JsonSerializable()
class DeleteNoteRequestDto {
  @JsonKey(name: "id")
  int? id;

  DeleteNoteRequestDto({this.id});

  factory DeleteNoteRequestDto.fromJson(Map<String, dynamic> json) =>
      _$DeleteNoteRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteNoteRequestDtoToJson(this);
}
