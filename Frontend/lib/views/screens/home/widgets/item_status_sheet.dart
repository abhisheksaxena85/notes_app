import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/network/dto/response/item_status.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

/// Long-press status picker for task and reminder cards. MISSED is derived
/// from the due time, so it is not offered as a manual choice. For a
/// [repeating] reminder it offers [RepeatingChoice]s instead.
Future<String?> showItemStatusSheet(
  BuildContext context, {
  required String currentStatus,
  bool repeating = false,
}) {
  final palette = context.daymark;
  final statusOptions = [
    (ItemStatus.pending, 'Pending', AppIcons.clock, palette.accent),
    (ItemStatus.completed, 'Completed', AppIcons.done, palette.success),
    (ItemStatus.rejected, 'Rejected', AppIcons.close, palette.danger),
  ];
  final repeatingOptions = [
    (RepeatingChoice.doneToday, 'Done for today', AppIcons.done, palette.success),
    (RepeatingChoice.missedToday, 'Missed today', AppIcons.close, palette.danger),
    (RepeatingChoice.stop, 'Stop repeating', AppIcons.repeat, palette.muted),
  ];
  final options = repeating ? repeatingOptions : statusOptions;

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: palette.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label, icon, color) in options)
              ListTile(
                leading: AppIcons.icon(icon, color: color),
                title: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                trailing: value == currentStatus
                    ? AppIcons.icon(AppIcons.check, color: palette.accent)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
          ],
        ),
      ),
    ),
  );
}
