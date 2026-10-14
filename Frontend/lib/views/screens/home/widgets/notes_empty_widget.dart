import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget notesEmptyWidget({
  required Future<void> Function() onRefresh,
}) {
  return RefreshIndicator(
    onRefresh: onRefresh,
    color: AppColors.brandColor,
    child: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: AppColors.priBlue00,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 56.sp,
                        color: AppColors.brandColor,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      "No Notes Found",
                      style: GoogleFonts.googleSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral90,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "You haven't created any notes yet.\nTap the '+' button below to get started!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sourceSans3(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.neutral70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
