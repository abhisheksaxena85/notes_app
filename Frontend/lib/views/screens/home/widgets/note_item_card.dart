import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/date/date_keys.dart';

Widget noteItemCard({
  required BuildContext context,
  required NoteItem note,
  VoidCallback? onTap,
  VoidCallback? onMoreTap,
}) {
  final palette = context.daymark;
  final bool isPinned = note.pinned ?? false;
  final String title = (note.title != null && note.title!.trim().isNotEmpty)
      ? note.title!
      : "Untitled Note";
  final String content = note.content ?? "";
  final String category = (note.category != null && note.category!.trim().isNotEmpty)
      ? note.category!
      : "General";
  final String dateText = _formatDate(note.updatedAt ?? note.createdAt);

  return Container(
    margin: EdgeInsets.only(bottom: 12.h),
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(
        color: isPinned ? palette.accent.withValues(alpha: 0.5) : palette.line,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: palette.brightness == Brightness.dark ? 0.2 : 0.03,
          ),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Title + Pin Icon + More Dots
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                  ),
                  if (isPinned) ...[
                    SizedBox(width: 8.w),
                    AppIcons.icon(
                      AppIcons.pin,
                      size: 16.sp,
                      color: palette.accent,
                    ),
                  ],
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: onMoreTap ?? onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: AppIcons.icon(
                        AppIcons.more,
                        size: 14.sp,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ],
              ),

              // Content preview
              if (content.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    color: palette.muted,
                  ),
                ),
              ],

              // Tag Chips Row
              SizedBox(height: 10.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 4.h,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                  ),
                  ...note.tagsList
                      .where((t) => t.toLowerCase() != category.toLowerCase())
                      .map((tag) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: palette.brightness == Brightness.dark
                            ? palette.surface
                            : palette.line.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: palette.line, width: 0.5),
                      ),
                      child: Text(
                        "#$tag",
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: palette.muted,
                        ),
                      ),
                    );
                  }),
                ],
              ),

              // Footer: Date + Arrow Up-Right
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      AppIcons.icon(
                        AppIcons.clock,
                        size: 13.sp,
                        color: palette.muted,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        dateText,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w400,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                  AppIcons.icon(
                    AppIcons.open,
                    size: 14.sp,
                    color: palette.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return "Recently";
  final parsed = DateKeys.instant(dateStr);
  if (parsed == null) return dateStr;
  const months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];
  final hour = parsed.hour > 12
      ? parsed.hour - 12
      : (parsed.hour == 0 ? 12 : parsed.hour);
  final period = parsed.hour >= 12 ? "PM" : "AM";
  final minuteStr = parsed.minute.toString().padLeft(2, '0');
  return "${months[parsed.month - 1]} ${parsed.day} · $hour:$minuteStr $period";
}
