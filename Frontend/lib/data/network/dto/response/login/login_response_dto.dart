import 'package:json_annotation/json_annotation.dart';
part 'login_response_dto.g.dart';

@JsonSerializable()
class LoginResponseDto {
  @JsonKey(name: "success")
  bool? success;
  @JsonKey(name: "message")
  String? message;
  @JsonKey(name: "data")
  Data? data;

  LoginResponseDto({this.success, this.message, this.data});

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseDtoToJson(this);
}

@JsonSerializable()
class Data {
  @JsonKey(name: "userId")
  int? userId;

  /// SEC-02: bearer token for every later request. Stored in secure storage
  /// by SessionService; never in SharedPreferences.
  @JsonKey(name: "accessToken")
  String? accessToken;

  /// When [accessToken] expires, ISO-8601 UTC.
  @JsonKey(name: "expiresAt")
  String? expiresAt;

  Data({this.userId, this.accessToken, this.expiresAt});

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

  Map<String, dynamic> toJson() => _$DataToJson(this);
}
