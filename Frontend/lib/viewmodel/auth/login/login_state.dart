import 'package:flutter/material.dart';
import 'package:notes_app/data/network/dto/response/login/login_response_dto.dart';

class LoginState {
  final LoginResponseDto? loginData;
  final TextEditingController? emailController;
  final TextEditingController? passwordController;
  final String? emailErrorMsg;
  final String? passwordErrorMsg;

  const LoginState({
    this.loginData,
    this.emailController,
    this.passwordController,
    this.emailErrorMsg,
    this.passwordErrorMsg,
  });

  LoginState copyWith({
    LoginResponseDto? loginData,
    TextEditingController? emailController,
    TextEditingController? passwordController,
    String? emailErrorMsg,
    String? passwordErrorMsg,
  }) {
    return LoginState(
      loginData: loginData ?? this.loginData,
      emailController: emailController ?? this.emailController,
      passwordController: passwordController ?? this.passwordController,
      emailErrorMsg: emailErrorMsg ?? this.emailErrorMsg,
      passwordErrorMsg: passwordErrorMsg ?? this.passwordErrorMsg,
    );
  }
}
