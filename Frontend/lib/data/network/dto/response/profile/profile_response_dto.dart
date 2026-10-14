import 'package:json_annotation/json_annotation.dart';
part 'profile_response_dto.g.dart';

@JsonSerializable()
class ProfileResponseDto {
  @JsonKey(name: "success")
  bool? success;
  @JsonKey(name: "message")
  String? message;
  @JsonKey(name: "data")
  ProfileData? data;

  ProfileResponseDto({this.success, this.message, this.data});

  factory ProfileResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileResponseDtoToJson(this);
}

@JsonSerializable()
class ProfileData {
  @JsonKey(name: "id")
  int? id;
  @JsonKey(name: "name")
  String? name;
  @JsonKey(name: "email")
  String? email;
  @JsonKey(name: "mobile")
  String? mobile;
  @JsonKey(name: "gender")
  String? gender;

  ProfileData({this.id, this.name, this.email, this.mobile, this.gender});

  factory ProfileData.fromJson(Map<String, dynamic> json) =>
      _$ProfileDataFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileDataToJson(this);
}
