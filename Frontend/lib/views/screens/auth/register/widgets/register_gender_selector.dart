import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget registerGenderSelector({
  required String selectedGender,
  required Function(String gender) onGenderChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Gender',
        style: GoogleFonts.sourceSans3(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.neutral80,
        ),
      ),
      SizedBox(height: 8.h),
      Row(
        children: [
          _genderOption(
            label: 'Male',
            value: 'male',
            selectedGender: selectedGender,
            onGenderChanged: onGenderChanged,
          ),
          SizedBox(width: 24.w),
          _genderOption(
            label: 'Female',
            value: 'female',
            selectedGender: selectedGender,
            onGenderChanged: onGenderChanged,
          ),
          SizedBox(width: 24.w),
          _genderOption(
            label: 'Other',
            value: 'other',
            selectedGender: selectedGender,
            onGenderChanged: onGenderChanged,
          ),
        ],
      ),
    ],
  );
}

Widget _genderOption({
  required String label,
  required String value,
  required String selectedGender,
  required Function(String gender) onGenderChanged,
}) {
  return GestureDetector(
    onTap: () => onGenderChanged(value),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: selectedGender,
          onChanged: (val) {
            if (val != null) onGenderChanged(val);
          },
          activeColor: AppColors.priBlue30,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        Text(
          label,
          style: GoogleFonts.sourceSans3(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.neutral90,
          ),
        ),
      ],
    ),
  );
}
