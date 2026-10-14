import 'package:json_annotation/json_annotation.dart';

part 'create_note_response_dto.g.dart';

@JsonSerializable()
class CreateNoteResponseDto {
  @JsonKey(name: "success")
  bool? success;
  @JsonKey(name: "message")
  String? message;
  @JsonKey(name: "data")
  CreateNoteData? data;

  CreateNoteResponseDto({this.success, this.message, this.data});

  factory CreateNoteResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CreateNoteResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateNoteResponseDtoToJson(this);
}

@JsonSerializable()
class CreateNoteData {
  @JsonKey(name: "noteId")
  int? noteId;

  CreateNoteData({this.noteId});

  factory CreateNoteData.fromJson(Map<String, dynamic> json) =>
      _$CreateNoteDataFromJson(json);

  Map<String, dynamic> toJson() => _$CreateNoteDataToJson(this);
}
