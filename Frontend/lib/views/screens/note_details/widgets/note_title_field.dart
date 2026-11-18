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

  return Builder(
    builder: (context) {
      final palette = context.daymark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: hasError ? palette.danger : palette.line,
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: "Title",
                hintStyle: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasError) ...[
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.only(left: 6.w),
              child: Text(
                errorText,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: palette.danger,
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}
