import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget profileInfoTile({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.priBlue00,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: AppColors.brandColor,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.sourceSans3(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral60,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value.isNotEmpty ? value : "N/A",
                style: GoogleFonts.googleSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral90,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
