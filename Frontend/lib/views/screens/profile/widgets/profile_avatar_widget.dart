import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget profileAvatarWidget({
  required String name,
  required String gender,
}) {
  IconData genderIcon;
  if (gender.toLowerCase() == "male") {
    genderIcon = Icons.male_rounded;
  } else if (gender.toLowerCase() == "female") {
    genderIcon = Icons.female_rounded;
  } else {
    genderIcon = Icons.person_rounded;
  }

  String initials = "";
  if (name.isNotEmpty) {
    final parts = name.trim().split(" ");
    if (parts.length >= 2) {
      initials = "${parts[0][0]}${parts[1][0]}".toUpperCase();
    } else {
      initials = parts[0][0].toUpperCase();
    }
  }

  return Column(
    children: [
      Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          color: AppColors.priBlue00,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.brandColor.withAlpha(80),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: GoogleFonts.googleSans(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.brandColor,
            ),
          ),
        ),
      ),
      SizedBox(height: 12.h),
      Text(
        name,
        style: GoogleFonts.googleSans(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.neutral90,
        ),
      ),
      SizedBox(height: 4.h),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            genderIcon,
            size: 16.sp,
            color: AppColors.neutral60,
          ),
          SizedBox(width: 4.w),
          Text(
            gender.isNotEmpty
                ? gender[0].toUpperCase() + gender.substring(1)
                : "N/A",
            style: GoogleFonts.sourceSans3(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.neutral60,
            ),
          ),
        ],
      ),
    ],
  );
}
