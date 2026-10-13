import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/data/di/dependency_injection.dart';
import 'package:notes_app/data/local/shared_preference/preference.dart';
import 'package:notes_app/data/local/shared_preference/preference_keys.dart';
import 'package:notes_app/data/network/dto/request/login/login_request_dto.dart';
import 'package:notes_app/data/network/dto/response/login/login_response_dto.dart';
import 'package:notes_app/data/repository/auth/login/login_repo.dart';
import 'package:notes_app/utils/res/snackbar.dart';
import 'package:notes_app/viewmodel/auth/login/login_state.dart';

class LoginViewmodel extends AsyncNotifier<LoginState> {
  /// MARK: Variables
  final LoginRepo _loginRepo = LoginRepo();

  /// MARK:DATA
  var loginData = LoginResponseDto();

  /// MARK:Controller
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Future<LoginState> build() async {
    return LoginState(
      emailController: emailController,
      passwordController: passwordController,
    );
  }

  void validatePassword(String value) {
    if (value.isEmpty || value == "") {
      state = AsyncData(
        state.value?.copyWith(passwordErrorMsg: "Field can't be empty") ??
            LoginState(),
      );
      return;
    }
    state = AsyncData(
      state.value?.copyWith(passwordErrorMsg: "") ?? LoginState(),
    );
  }

  void validateEmail(String value) {
    if (value.isEmpty) {
      state = AsyncData(
        state.value?.copyWith(emailErrorMsg: "Field can't be empty") ??
            LoginState(),
      );
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value)) {
      state = AsyncData(
        state.value?.copyWith(emailErrorMsg: "Enter a valid email address") ??
            LoginState(),
      );
      return;
    }
    state = AsyncData(state.value?.copyWith(emailErrorMsg: "") ?? LoginState());
  }

  Future<void> loginUser(BuildContext context) async {
    state = AsyncLoading();
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      log("Login Attempt: $email, $password");
      LoginResponseDto response = await _loginRepo.login(
        LoginRequestDto(email: email, password: password),
      );
      if (response.success == true) {
        loginData = response;
        await getIt<Preference>().setInt(
          PreferenceKeys.USER_ID,
          response.data?.userId ?? 0,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          failedSnackBar(response.message ?? "Something went wrong!"),
        );
      }
      state = AsyncData(LoginState(loginData: loginData));
      return;
    } catch (e) {
      log("Error while logging in user! $e");
      state = AsyncError(e.toString(), StackTrace.current);
    } finally {
      state = AsyncData(LoginState(loginData: loginData));
    }
  }
}
