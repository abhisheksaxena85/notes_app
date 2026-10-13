import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget registerLoginLink({
  required BuildContext context,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        "Already have an account?",
        style: GoogleFonts.sourceSans3(
          color: AppColors.neutral80,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(width: 4.w),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text("Login"),
      ),
    ],
  );
}
