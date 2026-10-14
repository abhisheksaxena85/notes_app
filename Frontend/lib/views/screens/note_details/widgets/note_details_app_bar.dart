import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteDetailsAppBar({
  required BuildContext context,
  required bool isEditMode,
  required bool isPinned,
  required VoidCallback onTogglePin,
  VoidCallback? onDelete,
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: AppColors.neutral20,
          width: 1,
        ),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.neutral90,
            size: 20.sp,
          ),
          tooltip: 'Back',
        ),
        Text(
          isEditMode ? "Edit Note" : "New Note",
          style: GoogleFonts.googleSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral100,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onTogglePin,
              tooltip: isPinned ? 'Unpin Note' : 'Pin Note',
              icon: Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: isPinned ? AppColors.warningColor : AppColors.neutral60,
                size: 22.sp,
              ),
            ),
            if (isEditMode && onDelete != null)
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete Note',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.errorColor,
                  size: 22.sp,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
