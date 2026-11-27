import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

/// Profile → Help & FAQ.
void showHelpSheet(BuildContext context) {
  final palette = context.daymark;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: palette.line,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text(
              "Help & FAQ",
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            SizedBox(height: 16.h),
            _buildFaqItem("How does the Calendar count notes?", "Notes are counted strictly by their original creation date (createdAt). Editing a note never shifts its calendar timestamp.", palette),
            Divider(color: palette.line, height: 20.h),
            _buildFaqItem("How do offline notes work?", "When you are offline, new notes are stored locally in an encrypted Drift SQLite queue. When network connectivity resumes, the background sync service pushes them to the server.", palette),
            Divider(color: palette.line, height: 20.h),
            _buildFaqItem("Can I organize notes with tags?", "Yes! You can assign categories and custom tags to any note. Search searches across titles, content, categories, and tags.", palette),
            SizedBox(height: 16.h),
          ],
        ),
      );
    },
  );
}

Widget _buildFaqItem(String question, String answer, DaymarkPalette palette) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        question,
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
      ),
      SizedBox(height: 4.h),
      Text(
        answer,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          color: palette.muted,
          height: 1.4,
        ),
      ),
    ],
  );
}
