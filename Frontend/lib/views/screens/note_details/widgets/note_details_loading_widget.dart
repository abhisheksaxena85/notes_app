import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteDetailsLoadingWidget() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: AppColors.brandColor,
          strokeWidth: 3,
        ),
        SizedBox(height: 16.h),
        Text(
          "Loading note details...",
          style: GoogleFonts.sourceSans3(
            fontSize: 14.sp,
            color: AppColors.neutral70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
