import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/viewmodel/auth/login/login_state.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/auth/register/register_screen.dart';
import 'package:notes_app/views/widgets/custom_text_field.dart';

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
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                AppIcons.splashLogo(context: context, size: 72.r),
                SizedBox(height: 16.h),
                Text(
                  "Daymark",
                  style: GoogleFonts.inter(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: palette.ink,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Sign in to your calm space",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: palette.muted,
                  ),
                ),
                SizedBox(height: 32.h),

                // Form Container
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(color: palette.line),
                  ),
                  child: Column(
                    children: [
                      customTextInputField(
                        controller: notifier.emailController,
                        labelText: 'Email Id',
                        isError: controller.value?.emailErrorMsg?.isNotEmpty ?? false,
                        errorText: controller.value?.emailErrorMsg ?? '',
                        onChanged: (String value) {
                          notifier.validateEmail(value);
                        },
                        length: 100,
                        inputFormatters: [],
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16.h),
                      customTextInputField(
                        controller: notifier.passwordController,
                        labelText: 'Password',
                        isError: controller.value?.passwordErrorMsg?.isNotEmpty ?? false,
                        errorText: controller.value?.passwordErrorMsg ?? '',
                        onChanged: (String value) {
                          notifier.validatePassword(value);
                        },
                        length: 100,
                        inputFormatters: [],
                        keyboardType: TextInputType.visiblePassword,
                      ),
                      SizedBox(height: 24.h),
                      loginButton(controller, context, ref, palette),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                signupButton(ref, context, palette),
              ],
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
    DaymarkPalette palette,
  ) {
    final isDark = palette.brightness == Brightness.dark;
    final bg = isDark ? palette.accent : palette.ink;
    final fg = isDark ? palette.background : palette.surface;

    return SizedBox(
      height: 48.h,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        onPressed: () {
          ref.read(loginController.notifier).loginUser(context);
        },
        child: state.when(
          data: (loginState) {
            return Text(
              "Sign In",
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            );
          },
          error: (o, stk) {
            return Text(
              "Retry",
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            );
          },
          loading: () {
            return SizedBox(
              width: 20.r,
              height: 20.r,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: fg,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget signupButton(
    WidgetRef ref,
    BuildContext context,
    DaymarkPalette palette,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: GoogleFonts.inter(
            color: palette.muted,
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
          ),
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
            style: GoogleFonts.inter(
              color: palette.accent,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
