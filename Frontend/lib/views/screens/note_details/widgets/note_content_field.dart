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

  return Builder(
    builder: (context) {
      final palette = context.daymark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(minHeight: 180.h),
            padding: EdgeInsets.all(16.r),
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
              minLines: 8,
              maxLines: 20,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: palette.ink,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: "Write your note description here...",
                hintStyle: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
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
