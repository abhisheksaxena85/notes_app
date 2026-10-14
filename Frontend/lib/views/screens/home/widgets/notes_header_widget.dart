import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget notesHeaderWidget({required VoidCallback onRefresh}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 12.w).copyWith(top: 12.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Notes",
              style: GoogleFonts.googleSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral100,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onRefresh,
          icon: Icon(
            Icons.refresh_rounded,
            color: AppColors.iconColor,
            size: 22.sp,
          ),
          tooltip: "Refresh notes",
        ),
      ],
    ),
  );
}
