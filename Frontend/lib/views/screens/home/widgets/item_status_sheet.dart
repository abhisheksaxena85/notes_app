import 'package:flutter/material.dart';
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
  const statusOptions = [
    (ItemStatus.pending, 'Pending', Icons.radio_button_unchecked_rounded, Color(0xFF166BBA)),
    (ItemStatus.completed, 'Completed', Icons.check_circle_rounded, Color(0xFF0A5B2F)),
    (ItemStatus.rejected, 'Rejected', Icons.cancel_outlined, Color(0xFFB95E58)),
  ];
  const repeatingOptions = [
    (RepeatingChoice.doneToday, 'Done for today', Icons.check_circle_rounded, Color(0xFF0A5B2F)),
    (RepeatingChoice.missedToday, 'Missed today', Icons.cancel_outlined, Color(0xFFB95E58)),
    (RepeatingChoice.stop, 'Stop repeating', Icons.stop_circle_outlined, Color(0xFF6B6B6B)),
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
                leading: Icon(icon, color: color),
                title: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                trailing: value == currentStatus
                    ? Icon(Icons.check_rounded, color: palette.accent)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
          ],
        ),
      ),
    ),
  );
}
