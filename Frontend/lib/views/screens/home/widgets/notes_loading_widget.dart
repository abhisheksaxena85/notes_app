import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget notesLoadingWidget() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 36.w,
          height: 36.w,
          child: CircularProgressIndicator(
            strokeWidth: 3.w,
            color: AppColors.brandColor,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          "Loading your notes...",
          style: GoogleFonts.sourceSans3(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.neutral70,
          ),
        ),
      ],
    ),
  );
}
