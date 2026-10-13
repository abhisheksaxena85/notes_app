import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/auth/register/register_state.dart';
import 'package:notes_app/viewmodel/controllers.dart';

Widget registerButton({
  required AsyncValue<RegisterState> state,
  required BuildContext context,
  required WidgetRef ref,
}) {
  return SizedBox(
    height: 40.h,
    width: 100.w,
    child: ElevatedButton(
      onPressed: () {
        ref.read(registerController.notifier).registerUser(context);
      },
      child: state.when(
        data: (registerState) {
          return Text("Sign Up");
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
