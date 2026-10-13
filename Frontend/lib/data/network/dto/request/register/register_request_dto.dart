import 'package:json_annotation/json_annotation.dart';
part 'register_request_dto.g.dart';

@JsonSerializable()
class RegisterRequestDto {
  String? name;
  String? email;
  String? mobile;
  String? gender;
  String? password;

  RegisterRequestDto({
    this.name,
    this.email,
    this.mobile,
    this.gender,
    this.password,
  });

  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestDtoToJson(this);
}
