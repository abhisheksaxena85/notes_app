import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';

Widget notesEmptyWidget({
  required Future<void> Function() onRefresh,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final palette = context.daymark;
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: palette.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 72.r,
                      height: 72.r,
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(22.r),
                        border: Border.all(color: palette.line),
                      ),
                      child: Center(
                        child: AppIcons.icon(
                          AppIcons.navNotes,
                          size: 32.sp,
                          color: palette.accent,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      "No notes yet",
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Your calm space is waiting.\nTap '+ New note' below to capture your thoughts.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
