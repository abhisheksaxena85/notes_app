import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/views/screens/home/widgets/item_status_sheet.dart';

Widget taskItemCard({
  required BuildContext context,
  required TaskItem task,
  required ValueChanged<bool> onToggleComplete,
  VoidCallback? onTap,
  VoidCallback? onDelete,
  ValueChanged<String>? onStatusSelected,
}) {
  final palette = context.daymark;
  final String status = task.effectiveStatus();
  final bool isCompleted = status == 'COMPLETED';
  final bool isMissedOrRejected = status == 'MISSED' || status == 'REJECTED';

  // Left Status Strip Color
  Color stripColor;
  if (isCompleted) {
    stripColor = const Color(0xFF0A5B2F); // Dark Green
  } else if (isMissedOrRejected) {
    stripColor = const Color(0xFFB95E58); // Danger Red
  } else {
    stripColor = const Color(0xFF166BBA); // Primary Blue
  }

  final String title = task.title.trim().isNotEmpty ? task.title : "Untitled Task";
  final String description = task.description ?? "";
  final String category = (task.category != null && task.category!.trim().isNotEmpty)
      ? task.category!
      : "General";

  return Container(
    margin: EdgeInsets.only(bottom: 12.h),
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18.r),
      border: Border.all(color: palette.line, width: 1),
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
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Status Strip
            Container(
              width: 5.w,
              color: stripColor,
            ),

            // Main Card Body
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onStatusSelected == null
                      ? null
                      : () async {
                          final selected = await showItemStatusSheet(
                            context,
                            currentStatus: task.status,
                          );
                          if (selected != null) onStatusSelected(selected);
                        },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row with Checkbox, Title, and Action
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Custom Animated Checkbox
                            GestureDetector(
                              onTap: () => onToggleComplete(!isCompleted),
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 22.r,
                                height: 22.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? const Color(0xFF0A5B2F)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isCompleted
                                        ? const Color(0xFF0A5B2F)
                                        : (isMissedOrRejected
                                            ? const Color(0xFFB95E58)
                                            : palette.muted.withValues(alpha: 0.6)),
                                    width: 1.8,
                                  ),
                                ),
                                child: isCompleted
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 14.sp,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            SizedBox(width: 10.w),

                            // Title
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  fontWeight: isCompleted
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: isCompleted
                                      ? palette.muted
                                      : palette.ink,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: palette.muted,
                                  decorationThickness: 2,
                                ),
                              ),
                            ),

                            if (onDelete != null) ...[
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: onDelete,
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: EdgeInsets.all(4.r),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18.sp,
                                    color: palette.muted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Description
                        if (description.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Padding(
                            padding: EdgeInsets.only(left: 32.w),
                            child: Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: isCompleted
                                    ? palette.muted.withValues(alpha: 0.7)
                                    : palette.ink.withValues(alpha: 0.75),
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: palette.muted,
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 10.h),

                        // Metadata / Pills Row
                        Padding(
                          padding: EdgeInsets.only(left: 32.w),
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 6.h,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Due Date / Time Chip
                              if (task.dueDate != null || task.dueTime != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.accentSoft,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppIcons.icon(
                                        AppIcons.clock,
                                        size: 11.sp,
                                        color: palette.accent,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        "${task.dueDate ?? ''} ${task.dueTime ?? ''}".trim(),
                                        style: GoogleFonts.inter(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                          color: palette.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Category Chip
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.line.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: palette.muted,
                                  ),
                                ),
                              ),

                              // Priority Tag (if HIGH or MEDIUM)
                              if (task.priority == 'HIGH')
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB95E58).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    "HIGH",
                                    style: GoogleFonts.inter(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFB95E58),
                                    ),
                                  ),
                                ),

                              // Status Badge if Missed or Rejected
                              if (isMissedOrRejected)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB95E58).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.inter(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFB95E58),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
