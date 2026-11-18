import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';

Widget noteDetailsAppBar({
  required BuildContext context,
  required bool isEditMode,
  required bool isPinned,
  required VoidCallback onTogglePin,
  VoidCallback? onDelete,
  VoidCallback? onExport,
}) {
  final palette = context.daymark;

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle pill matching Figma (width 38, height 4, rx 2)
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

        // Header Row: Back/Close + Title + Pin Button + (Delete if edit mode)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.line),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 20.sp,
                        color: palette.ink,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  isEditMode ? "Edit note" : "New note",
                  style: GoogleFonts.inter(
                    fontSize: 23.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: palette.ink,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEditMode && onExport != null) ...[
                  IconButton(
                    onPressed: onExport,
                    tooltip: 'Export Note',
                    icon: Icon(
                      Icons.file_download_outlined,
                      color: palette.ink,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 4.w),
                ],
                if (isEditMode && onDelete != null) ...[
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete Note',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: palette.danger,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 6.w),
                ],
                // Pin button matching Figma (36x36 rx 18)
                GestureDetector(
                  onTap: onTogglePin,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: isPinned ? palette.accentSoft : palette.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPinned ? palette.accent : palette.line,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: AppIcons.icon(
                        AppIcons.pin,
                        size: 16.sp,
                        color: isPinned ? palette.accent : palette.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
