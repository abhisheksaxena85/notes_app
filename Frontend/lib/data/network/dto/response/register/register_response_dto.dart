import 'package:json_annotation/json_annotation.dart';
part 'register_response_dto.g.dart';

@JsonSerializable()
class RegisterResponseDto {
  @JsonKey(name: "success")
  bool? success;
  @JsonKey(name: "message")
  String? message;
  @JsonKey(name: "data")
  RegisterData? data;

  RegisterResponseDto({this.success, this.message, this.data});

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterResponseDtoToJson(this);
}

@JsonSerializable()
class RegisterData {
  @JsonKey(name: "userId")
  int? userId;

  /// SEC-02: bearer token for every later request. Stored in secure storage
  /// by SessionService; never in SharedPreferences.
  @JsonKey(name: "accessToken")
  String? accessToken;

  /// When [accessToken] expires, ISO-8601 UTC.
  @JsonKey(name: "expiresAt")
  String? expiresAt;

  RegisterData({this.userId, this.accessToken, this.expiresAt});

  factory RegisterData.fromJson(Map<String, dynamic> json) =>
      _$RegisterDataFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterDataToJson(this);
}
