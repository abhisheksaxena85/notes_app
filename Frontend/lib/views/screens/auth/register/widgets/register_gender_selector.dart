import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget registerGenderSelector({
  required String selectedGender,
  required Function(String gender) onGenderChanged,
}) {
  return Builder(
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: GoogleFonts.sourceSans3(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: context.daymark.muted,
          ),
        ),
        SizedBox(height: 8.h),
        RadioGroup<String>(
          groupValue: selectedGender,
          onChanged: (val) {
            if (val != null) onGenderChanged(val);
          },
          child: Row(
            children: [
              _genderOption(
                label: 'Male',
                value: 'male',
                onGenderChanged: onGenderChanged,
              ),
              SizedBox(width: 24.w),
              _genderOption(
                label: 'Female',
                value: 'female',
                onGenderChanged: onGenderChanged,
              ),
              SizedBox(width: 24.w),
              _genderOption(
                label: 'Other',
                value: 'other',
                onGenderChanged: onGenderChanged,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _genderOption({
  required String label,
  required String value,
  required Function(String gender) onGenderChanged,
}) {
  return Builder(
    builder: (context) => GestureDetector(
      onTap: () => onGenderChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            activeColor: context.daymark.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            label,
            style: GoogleFonts.sourceSans3(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: context.daymark.ink,
            ),
          ),
        ],
      ),
    ),
  );
}
