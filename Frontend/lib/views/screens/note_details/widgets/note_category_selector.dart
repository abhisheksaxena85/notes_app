import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteCategorySelector({
  required String selectedCategory,
  required Function(String) onCategorySelected,
}) {
  const categories = ["General", "Work", "Personal", "Planning", "Ideas", "Study"];

  return Builder(
    builder: (context) {
      final palette = context.daymark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CATEGORY",
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: palette.muted,
            ),
          ),
          SizedBox(height: 8.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: categories.map((cat) {
                final isSelected =
                    cat.toLowerCase() == selectedCategory.toLowerCase();
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => onCategorySelected(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.accentSoft
                            : palette.surface,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isSelected ? palette.accent : palette.line,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? palette.accent : palette.muted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    },
  );
}
