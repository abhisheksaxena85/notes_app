import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteCategorySelector({
  required String selectedCategory,
  required Function(String) onCategorySelected,
}) {
  const categories = ["General", "Personal", "Work", "Study", "Ideas", "Tasks"];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Category",
        style: GoogleFonts.googleSans(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.neutral70,
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
                borderRadius: BorderRadius.circular(20.r),
                onTap: () => onCategorySelected(cat),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandColor
                        : AppColors.neutral10,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandColor
                          : AppColors.neutral30,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.googleSans(
                      fontSize: 12.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.neutral80,
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
}
