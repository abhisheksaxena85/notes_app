import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/date/date_keys.dart';

Widget noteMetaInfoWidget({
  String? createdAt,
  String? updatedAt,
}) {
  final hasCreated = createdAt != null && createdAt.trim().isNotEmpty;
  final hasUpdated = updatedAt != null && updatedAt.trim().isNotEmpty;

  if (!hasCreated && !hasUpdated) return const SizedBox.shrink();

  return Builder(
    builder: (context) {
      final palette = context.daymark;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (hasCreated)
              Row(
                children: [
                  AppIcons.icon(
                    AppIcons.clock,
                    size: 13.sp,
                    color: palette.muted,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Created: ${_formatDate(createdAt)}",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            if (hasUpdated)
              Row(
                children: [
                  AppIcons.icon(
                    AppIcons.open,
                    size: 13.sp,
                    color: palette.muted,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Updated: ${_formatDate(updatedAt)}",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );
}

String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return "";
  final parsed = DateKeys.instant(dateStr);
  if (parsed == null) return dateStr;
  const months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];
  return "${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}";
}
