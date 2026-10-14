import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteContentField({
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
        minLines: 8,
        maxLines: 18,
        keyboardType: TextInputType.multiline,
        style: GoogleFonts.sourceSans3(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.neutral90,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: "Write your note description here...",
          hintStyle: GoogleFonts.sourceSans3(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.neutral50,
          ),
          filled: true,
          fillColor: AppColors.neutral05,
          contentPadding: EdgeInsets.all(14.r),
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
