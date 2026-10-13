import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/auth/login/login_state.dart';
import 'package:notes_app/viewmodel/controllers.dart';
import 'package:notes_app/views/screens/auth/register/register_screen.dart';
import 'package:notes_app/views/widgets/custom_text_field.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var controller = ref.watch(loginController);
    var notifier = ref.read(loginController.notifier);
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 20.h),
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
            SizedBox(height: 30.h),
            loginButton(controller, context, ref),
            SizedBox(height: 20.h),
            signupButton(ref, context),
          ],
        ),
      ),
    );
  }

  Widget loginButton(
    AsyncValue<LoginState> state,
    BuildContext context,
    WidgetRef ref,
  ) {
    return SizedBox(
      height: 40.h,
      width: 100.w,
      child: ElevatedButton(
        onPressed: () {
          ref.read(loginController.notifier).loginUser(context);
        },
        child: state.when(
          data: (loginState) {
            return Text("Login");
          },
          error: (o, stk) {
            return Text("Retry");
          },
          loading: () {
            return CircularProgressIndicator(color: AppColors.black);
          },
        ),
      ),
    );
  }

  Widget signupButton(WidgetRef ref, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: GoogleFonts.sourceSans3(
            color: AppColors.neutral80,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 4.w),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegisterScreen()),
            );
          },
          child: Text("Sign Up"),
        ),
      ],
    );
  }
}
