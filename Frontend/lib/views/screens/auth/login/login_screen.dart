import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/viewmodel/auth/login/login_state.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/auth/register/register_screen.dart';
import 'package:notes_app/views/widgets/custom_text_field.dart';
import 'package:notes_app/views/widgets/primary_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.daymark;
    var controller = ref.watch(loginController);
    var notifier = ref.read(loginController.notifier);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: AppIcons.logo(size: 56)),
                  const SizedBox(height: 16),
                  Text(
                    "Daymark",
                    textAlign: TextAlign.center,
                    style: DaymarkText.title.copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Sign in to your calm space",
                    textAlign: TextAlign.center,
                    style: DaymarkText.preview.copyWith(color: palette.muted),
                  ),
                  const SizedBox(height: 28),
                  customTextInputField(
                    controller: notifier.emailController,
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: AppIcons.email,
                    isError: controller.value?.emailErrorMsg?.isNotEmpty ?? false,
                    errorText: controller.value?.emailErrorMsg ?? '',
                    onChanged: (String value) {
                      notifier.validateEmail(value);
                    },
                    length: 100,
                    inputFormatters: [],
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  customTextInputField(
                    controller: notifier.passwordController,
                    labelText: 'Password',
                    prefixIcon: AppIcons.password,
                    obscureText: true,
                    isError: controller.value?.passwordErrorMsg?.isNotEmpty ?? false,
                    errorText: controller.value?.passwordErrorMsg ?? '',
                    onChanged: (String value) {
                      notifier.validatePassword(value);
                    },
                    length: 100,
                    inputFormatters: [],
                    keyboardType: TextInputType.visiblePassword,
                  ),
                  const SizedBox(height: 24),
                  loginButton(controller, context, ref),
                  const SizedBox(height: 16),
                  signupButton(context, palette),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget loginButton(
    AsyncValue<LoginState> state,
    BuildContext context,
    WidgetRef ref,
  ) {
    return PrimaryButton(
      label: state.hasError ? "Retry" : "Sign in",
      loading: state.isLoading,
      onPressed: () {
        ref.read(loginController.notifier).loginUser(context);
      },
    );
  }

  Widget signupButton(BuildContext context, DaymarkPalette palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: DaymarkText.custom(13.5, FontWeight.w400).copyWith(color: palette.muted),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: Text(
            "Create one",
            style: DaymarkText.custom(13.5, FontWeight.w600).copyWith(color: palette.accent),
          ),
        ),
      ],
    );
  }
}
