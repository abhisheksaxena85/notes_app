import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/network/dto/request/register/register_request_dto.dart';
import 'package:notes_app/data/network/dto/response/register/register_response_dto.dart';
import 'package:notes_app/data/repository/auth/register/register_repo.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/viewmodel/auth/register/register_state.dart';

class RegisterViewmodel extends AsyncNotifier<RegisterState> {
  /// MARK: Variables
  final RegisterRepo _registerRepo = RegisterRepo();

  /// MARK:DATA
  var registerData = RegisterResponseDto();

  /// MARK:Controller
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  /// MARK:Data Variables
  String selectedGender = "male";

  @override
  Future<RegisterState> build() async {
    return RegisterState(
      nameController: nameController,
      emailController: emailController,
      mobileController: mobileController,
      passwordController: passwordController,
      selectedGender: selectedGender,
    );
  }

  void validateName(String value) {
    if (value.isEmpty || value == "") {
      state = AsyncData(
        state.value?.copyWith(nameErrorMsg: "Field can't be empty") ??
            RegisterState(),
      );
      return;
    }
    state = AsyncData(
      state.value?.copyWith(nameErrorMsg: "") ?? RegisterState(),
    );
  }

  void validateEmail(String value) {
    if (value.isEmpty) {
      state = AsyncData(
        state.value?.copyWith(emailErrorMsg: "Field can't be empty") ??
            RegisterState(),
      );
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value)) {
      state = AsyncData(
        state.value?.copyWith(emailErrorMsg: "Enter a valid email address") ??
            RegisterState(),
      );
      return;
    }
    state = AsyncData(
      state.value?.copyWith(emailErrorMsg: "") ?? RegisterState(),
    );
  }

  void validateMobile(String value) {
    if (value.isEmpty || value == "") {
      state = AsyncData(
        state.value?.copyWith(mobileErrorMsg: "Field can't be empty") ??
            RegisterState(),
      );
      return;
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      state = AsyncData(
        state.value?.copyWith(mobileErrorMsg: "Enter a valid 10-digit mobile number") ??
            RegisterState(),
      );
      return;
    }
    state = AsyncData(
      state.value?.copyWith(mobileErrorMsg: "") ?? RegisterState(),
    );
  }

  void validatePassword(String value) {
    if (value.isEmpty || value == "") {
      state = AsyncData(
        state.value?.copyWith(passwordErrorMsg: "Field can't be empty") ??
            RegisterState(),
      );
      return;
    }
    state = AsyncData(
      state.value?.copyWith(passwordErrorMsg: "") ?? RegisterState(),
    );
  }

  void setGender(String gender) {
    selectedGender = gender;
    state = AsyncData(
      state.value?.copyWith(selectedGender: gender) ?? RegisterState(),
    );
  }

  Future<void> registerUser(BuildContext context) async {
    state = AsyncLoading();
    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final mobile = mobileController.text.trim();
      final password = passwordController.text.trim();
      log("Register Attempt: $name, $email, $mobile, $selectedGender");
      RegisterResponseDto response = await _registerRepo.register(
        RegisterRequestDto(
          name: name,
          email: email,
          mobile: mobile,
          gender: selectedGender,
          password: password,
        ),
      );
      if (response.success == true) {
        registerData = response;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            successSnackBar(response.message ?? "User created successfully!"),
          );
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            failedSnackBar(response.message ?? "Something went wrong!"),
          );
        }
      }
      state = AsyncData(RegisterState(registerData: registerData));
      return;
    } catch (e) {
      log("Error while registering user! $e");
      state = AsyncError(e.toString(), StackTrace.current);
    } finally {
      state = AsyncData(RegisterState(registerData: registerData));
    }
  }
}
