import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget noteItemCard({
  required NoteItem note,
  VoidCallback? onTap,
}) {
  final bool isPinned = note.pinned ?? false;
  final String title = (note.title != null && note.title!.trim().isNotEmpty)
      ? note.title!
      : "Untitled Note";
  final String content = note.content ?? "";
  final String category = note.category ?? "General";
  final String dateText = _formatDate(note.updatedAt ?? note.createdAt);

  return Container(
    margin: EdgeInsets.only(bottom: 12.h),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(
        color: isPinned ? AppColors.brandColor.withAlpha(100) : AppColors.neutral30,
        width: isPinned ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withAlpha(12),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.priBlue00,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.googleSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.priBlue30,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isPinned)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.push_pin_rounded,
                          size: 16.sp,
                          color: AppColors.warningColor,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          "Pinned",
                          style: GoogleFonts.googleSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warningColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.googleSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral90,
                ),
              ),
              if (content.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sourceSans3(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    color: AppColors.neutral80,
                  ),
                ),
              ],
              if (dateText.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13.sp,
                      color: AppColors.neutral60,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      dateText,
                      style: GoogleFonts.sourceSans3(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutral60,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
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
