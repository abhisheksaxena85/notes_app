import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteTitleField({
  required TextEditingController controller,
  required Function(String) onChanged,
  String? errorText,
}) {
  final hasError = errorText != null && errorText.isNotEmpty;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.googleSans(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.neutral100,
        ),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: "Title",
          hintStyle: GoogleFonts.googleSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.neutral50,
          ),
          filled: true,
          fillColor: AppColors.neutral05,
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: hasError ? AppColors.errorColor : AppColors.neutral30,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: hasError ? AppColors.errorColor : AppColors.neutral30,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: hasError ? AppColors.errorColor : AppColors.brandColor,
              width: 1.5,
            ),
          ),
        ),
      ),
      if (hasError) ...[
        SizedBox(height: 4.h),
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            errorText,
            style: GoogleFonts.sourceSans3(
              fontSize: 12.sp,
              color: AppColors.errorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ],
  );
}
