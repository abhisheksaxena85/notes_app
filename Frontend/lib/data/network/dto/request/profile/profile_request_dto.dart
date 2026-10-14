import 'package:json_annotation/json_annotation.dart';
part 'profile_request_dto.g.dart';

@JsonSerializable()
class ProfileRequestDto {
  int? id;

  ProfileRequestDto({this.id});

  factory ProfileRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileRequestDtoToJson(this);
}
