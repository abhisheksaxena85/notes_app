import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget profileLoadingWidget() {
  return Builder(
    builder: (context) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36.w,
            height: 36.w,
            child: CircularProgressIndicator(
              strokeWidth: 3.w,
              color: context.daymark.accent,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "Loading profile...",
            style: GoogleFonts.sourceSans3(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: context.daymark.muted,
            ),
          ),
        ],
      ),
    ),
  );
}
