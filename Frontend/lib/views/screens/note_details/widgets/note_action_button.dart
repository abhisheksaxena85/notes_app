import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteActionButton({
  required bool isEditMode,
  required bool isSaving,
  required VoidCallback onPressed,
}) {
  return Builder(
    builder: (context) {
      final palette = context.daymark;
      final isDark = palette.brightness == Brightness.dark;
      final bg = isDark ? palette.accent : palette.ink;
      final fg = isDark ? palette.background : palette.surface;

      return SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          onPressed: isSaving ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            elevation: 0,
          ),
          child: isSaving
              ? SizedBox(
                  height: 22.r,
                  width: 22.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: fg,
                  ),
                )
              : Text(
                  isEditMode ? "Update note" : "Save note",
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
        ),
      );
    },
  );
}
