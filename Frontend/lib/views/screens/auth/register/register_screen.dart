import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/auth/register/widgets/register_button.dart';
import 'package:notes_app/views/screens/auth/register/widgets/register_email_field.dart';
import 'package:notes_app/views/screens/auth/register/widgets/register_gender_selector.dart';
import 'package:notes_app/views/screens/auth/register/widgets/register_login_link.dart';
import 'package:notes_app/views/screens/auth/register/widgets/register_mobile_field.dart';
import 'package:notes_app/views/screens/auth/register/widgets/register_name_field.dart';
import 'package:notes_app/views/screens/auth/register/widgets/register_password_field.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.daymark;
    var controller = ref.watch(registerController);
    var notifier = ref.read(registerController.notifier);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                      icon: AppIcons.icon(
                        AppIcons.back,
                        color: palette.ink,
                        size: 20,
                      ),
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                    ),
                  ),
                  Center(child: AppIcons.logo(size: 56)),
                  const SizedBox(height: 16),
                  Text(
                    "Create account",
                    textAlign: TextAlign.center,
                    style: DaymarkText.title.copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Start saving your thoughts with Daymark",
                    textAlign: TextAlign.center,
                    style: DaymarkText.preview.copyWith(color: palette.muted),
                  ),
                  const SizedBox(height: 28),
                  registerNameField(
                    controller: notifier.nameController,
                    isError:
                        controller.value?.nameErrorMsg?.isNotEmpty ?? false,
                    errorText: controller.value?.nameErrorMsg ?? '',
                    onChanged: (String value) {
                      notifier.validateName(value);
                    },
                  ),
                  const SizedBox(height: 14),
                  registerEmailField(
                    controller: notifier.emailController,
                    isError:
                        controller.value?.emailErrorMsg?.isNotEmpty ?? false,
                    errorText: controller.value?.emailErrorMsg ?? '',
                    onChanged: (String value) {
                      notifier.validateEmail(value);
                    },
                  ),
                  const SizedBox(height: 14),
                  registerMobileField(
                    controller: notifier.mobileController,
                    isError:
                        controller.value?.mobileErrorMsg?.isNotEmpty ?? false,
                    errorText: controller.value?.mobileErrorMsg ?? '',
                    onChanged: (String value) {
                      notifier.validateMobile(value);
                    },
                  ),
                  const SizedBox(height: 14),
                  registerPasswordField(
                    controller: notifier.passwordController,
                    isError:
                        controller.value?.passwordErrorMsg?.isNotEmpty ?? false,
                    errorText: controller.value?.passwordErrorMsg ?? '',
                    onChanged: (String value) {
                      notifier.validatePassword(value);
                    },
                  ),
                  const SizedBox(height: 14),
                  registerGenderSelector(
                    selectedGender: controller.value?.selectedGender ?? 'male',
                    onGenderChanged: (String gender) {
                      notifier.setGender(gender);
                    },
                  ),
                  const SizedBox(height: 24),
                  registerButton(state: controller, context: context, ref: ref),
                  const SizedBox(height: 16),
                  registerLoginLink(context: context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
