import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteDetailsErrorWidget({
  required String message,
  required VoidCallback onRetry,
}) {
  return Builder(
    builder: (context) {
      final palette = context.daymark;
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  color: palette.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 32.sp,
                  color: palette.danger,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Failed to Load Note",
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                message.isNotEmpty
                    ? message
                    : "Something went wrong while fetching note details.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: palette.muted,
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: AppIcons.icon(AppIcons.sync, size: 18.sp),
                label: Text(
                  "Retry",
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.ink,
                  foregroundColor: palette.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
