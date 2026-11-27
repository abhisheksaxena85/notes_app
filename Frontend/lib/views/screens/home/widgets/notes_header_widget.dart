import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget notesHeaderWidget({
  required BuildContext context,
  required VoidCallback onRefresh,
  int noteCount = 0,
  String? userName,
  String? title,
  String? itemLabel,
}) {
  final palette = context.daymark;
  final now = DateTime.now();
  final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  final months = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
  ];
  final dayName = days[now.weekday - 1];
  final monthName = months[now.month - 1];
  final dateStr = '$dayName  ·  $monthName ${now.day}';

  final greetingName = (userName != null && userName.trim().isNotEmpty)
      ? userName.trim().toUpperCase()
      : 'EMIAI';

  final displayLabel = itemLabel ?? (noteCount == 1 ? "ITEM" : "ITEMS");

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(top: 14.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top greeting & note count pill row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'GOOD DAY, $greetingName',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: palette.muted,
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$noteCount $displayLabel',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: palette.accent,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                IconButton(
                  onPressed: onRefresh,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: AppIcons.icon(
                    AppIcons.sync,
                    color: palette.muted,
                    size: 18.sp,
                  ),
                  tooltip: "Refresh items",
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 6.h),

        // Screen title
        Text(
          title ?? 'Workspace',
          style: GoogleFonts.inter(
            fontSize: 31.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
            color: palette.ink,
          ),
        ),
        SizedBox(height: 4.h),

        // Subtitle Date
        Text(
          dateStr,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
            color: palette.muted,
          ),
        ),
      ],
    ),
  );
}
