import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

/// The title + message dialog used by About and Privacy & security.
void showInfoDialog(BuildContext context, String title, String message) {
  final palette = context.daymark;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: palette.line),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          color: palette.muted,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            "OK",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: palette.accent,
            ),
          ),
        ),
      ],
    ),
  );
}
