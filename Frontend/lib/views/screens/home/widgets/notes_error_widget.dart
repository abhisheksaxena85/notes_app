import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget notesErrorWidget({
  required String message,
  required VoidCallback onRetry,
}) {
  return Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.redBgLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48.sp,
              color: AppColors.errorColor,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "Failed to Load Notes",
            style: GoogleFonts.googleSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral90,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message.isNotEmpty ? message : "Something went wrong while fetching notes.",
            textAlign: TextAlign.center,
            style: GoogleFonts.sourceSans3(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.neutral70,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded, size: 18.sp, color: AppColors.white),
            label: Text(
              "Retry",
              style: GoogleFonts.googleSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandColor,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
