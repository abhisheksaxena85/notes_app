import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteDetailsLoadingWidget() {
  return Builder(
    builder: (context) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: context.daymark.accent,
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            "Loading note details...",
            style: GoogleFonts.sourceSans3(
              fontSize: 14.sp,
              color: context.daymark.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
