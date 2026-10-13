import 'package:flutter/material.dart';
import 'package:notes_app/data/network/dto/response/register/register_response_dto.dart';

class RegisterState {
  final RegisterResponseDto? registerData;
  final TextEditingController? nameController;
  final TextEditingController? emailController;
  final TextEditingController? mobileController;
  final TextEditingController? passwordController;
  final String? nameErrorMsg;
  final String? emailErrorMsg;
  final String? mobileErrorMsg;
  final String? passwordErrorMsg;
  final String? selectedGender;

  const RegisterState({
    this.registerData,
    this.nameController,
    this.emailController,
    this.mobileController,
    this.passwordController,
    this.nameErrorMsg,
    this.emailErrorMsg,
    this.mobileErrorMsg,
    this.passwordErrorMsg,
    this.selectedGender,
  });

  RegisterState copyWith({
    RegisterResponseDto? registerData,
    TextEditingController? nameController,
    TextEditingController? emailController,
    TextEditingController? mobileController,
    TextEditingController? passwordController,
    String? nameErrorMsg,
    String? emailErrorMsg,
    String? mobileErrorMsg,
    String? passwordErrorMsg,
    String? selectedGender,
  }) {
    return RegisterState(
      registerData: registerData ?? this.registerData,
      nameController: nameController ?? this.nameController,
      emailController: emailController ?? this.emailController,
      mobileController: mobileController ?? this.mobileController,
      passwordController: passwordController ?? this.passwordController,
      nameErrorMsg: nameErrorMsg ?? this.nameErrorMsg,
      emailErrorMsg: emailErrorMsg ?? this.emailErrorMsg,
      mobileErrorMsg: mobileErrorMsg ?? this.mobileErrorMsg,
      passwordErrorMsg: passwordErrorMsg ?? this.passwordErrorMsg,
      selectedGender: selectedGender ?? this.selectedGender,
    );
  }
}
