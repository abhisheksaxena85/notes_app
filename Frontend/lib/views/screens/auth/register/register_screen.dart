import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    var controller = ref.watch(registerController);
    var notifier = ref.read(registerController.notifier);
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              registerNameField(
                controller: notifier.nameController,
                isError: controller.value?.nameErrorMsg?.isNotEmpty ?? false,
                errorText: controller.value?.nameErrorMsg ?? '',
                onChanged: (String value) {
                  notifier.validateName(value);
                },
              ),
              SizedBox(height: 20.h),
              registerEmailField(
                controller: notifier.emailController,
                isError: controller.value?.emailErrorMsg?.isNotEmpty ?? false,
                errorText: controller.value?.emailErrorMsg ?? '',
                onChanged: (String value) {
                  notifier.validateEmail(value);
                },
              ),
              SizedBox(height: 20.h),
              registerMobileField(
                controller: notifier.mobileController,
                isError: controller.value?.mobileErrorMsg?.isNotEmpty ?? false,
                errorText: controller.value?.mobileErrorMsg ?? '',
                onChanged: (String value) {
                  notifier.validateMobile(value);
                },
              ),
              SizedBox(height: 20.h),
              registerPasswordField(
                controller: notifier.passwordController,
                isError:
                    controller.value?.passwordErrorMsg?.isNotEmpty ?? false,
                errorText: controller.value?.passwordErrorMsg ?? '',
                onChanged: (String value) {
                  notifier.validatePassword(value);
                },
              ),
              SizedBox(height: 20.h),
              registerGenderSelector(
                selectedGender: controller.value?.selectedGender ?? 'male',
                onGenderChanged: (String gender) {
                  notifier.setGender(gender);
                },
              ),
              SizedBox(height: 30.h),
              registerButton(
                state: controller,
                context: context,
                ref: ref,
              ),
              SizedBox(height: 20.h),
              registerLoginLink(context: context),
            ],
          ),
        ),
      ),
    );
  }
}
