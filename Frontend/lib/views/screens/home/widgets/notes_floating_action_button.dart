import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/res/snackbar.dart';

Widget notesFloatingActionButton({
  required BuildContext context,
  VoidCallback? onPressed,
}) {
  return FloatingActionButton(
    heroTag: 'add_note_fab',
    backgroundColor: AppColors.brandColor,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.r),
    ),
    onPressed: onPressed ??
        () {
          ScaffoldMessenger.of(context).showSnackBar(
            waitingSnackbar("Add note feature will be implemented later!"),
          );
        },
    child: Icon(
      Icons.add,
      color: AppColors.white,
      size: 26.sp,
    ),
  );
}
