import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget notesLoadingWidget() {
  return Builder(
    builder: (context) {
      final palette = context.daymark;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 32.r,
              height: 32.r,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.accent,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Loading your notes...",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: palette.muted,
              ),
            ),
          ],
        ),
      );
    },
  );
}
