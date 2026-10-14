import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteMetaInfoWidget({
  String? createdAt,
  String? updatedAt,
}) {
  final hasCreated = createdAt != null && createdAt.trim().isNotEmpty;
  final hasUpdated = updatedAt != null && updatedAt.trim().isNotEmpty;

  if (!hasCreated && !hasUpdated) return const SizedBox.shrink();

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
    decoration: BoxDecoration(
      color: AppColors.neutral10,
      borderRadius: BorderRadius.circular(8.r),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (hasCreated)
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 12.sp, color: AppColors.neutral60),
              SizedBox(width: 4.w),
              Text(
                "Created: ${_formatDate(createdAt)}",
                style: GoogleFonts.sourceSans3(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral70,
                ),
              ),
            ],
          ),
        if (hasUpdated)
          Row(
            children: [
              Icon(Icons.update_rounded, size: 12.sp, color: AppColors.neutral60),
              SizedBox(width: 4.w),
              Text(
                "Updated: ${_formatDate(updatedAt)}",
                style: GoogleFonts.sourceSans3(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral70,
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return "";
  try {
    final parsed = DateTime.parse(dateStr);
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}";
  } catch (_) {
    return dateStr;
  }
}
