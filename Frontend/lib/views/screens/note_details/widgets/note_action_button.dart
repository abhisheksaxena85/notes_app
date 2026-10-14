import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteActionButton({
  required bool isEditMode,
  required bool isSaving,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 48.h,
    child: ElevatedButton(
      onPressed: isSaving ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandColor,
        disabledBackgroundColor: AppColors.brandColor.withAlpha(160),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 2,
      ),
      child: isSaving
          ? SizedBox(
              height: 22.h,
              width: 22.h,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isEditMode ? Icons.check_circle_outline_rounded : Icons.add_circle_outline_rounded,
                  color: AppColors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  isEditMode ? "Update Note" : "Create Note",
                  style: GoogleFonts.googleSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
    ),
  );
}
