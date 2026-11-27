import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/viewmodel/auth/register/register_state.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/widgets/primary_button.dart';

Widget registerButton({
  required AsyncValue<RegisterState> state,
  required BuildContext context,
  required WidgetRef ref,
}) {
  return PrimaryButton(
    label: state.hasError ? "Retry" : "Sign up",
    loading: state.isLoading,
    onPressed: () {
      ref.read(registerController.notifier).registerUser(context);
    },
  );
}
