import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
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
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: palette.ink,
                    size: 20.sp,
                  ),
                ),
              ),
              AppIcons.splashLogo(context: context, size: 64.r),
              SizedBox(height: 12.h),
              Text(
                "Create Account",
                style: GoogleFonts.inter(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: palette.ink,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Start saving your thoughts with Daymark",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: palette.muted,
                ),
              ),
              SizedBox(height: 24.h),

              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: palette.line),
                ),
                child: Column(
                  children: [
                    registerNameField(
                      controller: notifier.nameController,
                      isError: controller.value?.nameErrorMsg?.isNotEmpty ?? false,
                      errorText: controller.value?.nameErrorMsg ?? '',
                      onChanged: (String value) {
                        notifier.validateName(value);
                      },
                    ),
                    SizedBox(height: 16.h),
                    registerEmailField(
                      controller: notifier.emailController,
                      isError: controller.value?.emailErrorMsg?.isNotEmpty ?? false,
                      errorText: controller.value?.emailErrorMsg ?? '',
                      onChanged: (String value) {
                        notifier.validateEmail(value);
                      },
                    ),
                    SizedBox(height: 16.h),
                    registerMobileField(
                      controller: notifier.mobileController,
                      isError: controller.value?.mobileErrorMsg?.isNotEmpty ?? false,
                      errorText: controller.value?.mobileErrorMsg ?? '',
                      onChanged: (String value) {
                        notifier.validateMobile(value);
                      },
                    ),
                    SizedBox(height: 16.h),
                    registerPasswordField(
                      controller: notifier.passwordController,
                      isError: controller.value?.passwordErrorMsg?.isNotEmpty ?? false,
                      errorText: controller.value?.passwordErrorMsg ?? '',
                      onChanged: (String value) {
                        notifier.validatePassword(value);
                      },
                    ),
                    SizedBox(height: 16.h),
                    registerGenderSelector(
                      selectedGender: controller.value?.selectedGender ?? 'male',
                      onGenderChanged: (String gender) {
                        notifier.setGender(gender);
                      },
                    ),
                    SizedBox(height: 24.h),
                    registerButton(
                      state: controller,
                      context: context,
                      ref: ref,
                    ),
                  ],
                ),
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
