/// @author Abhishek Saxena
/// Creation Date: 19-09-2025
/// Copyright © EL Nova Labs 2025. All rights reserved.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

SnackBar failedSnackBar(String message) {
  return SnackBar(
    content: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.errorColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: GoogleFonts.roboto(
              color: AppColors.errorColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
    duration: const Duration(seconds: 4),
    backgroundColor: AppColors.redBg,
    showCloseIcon: true,
    closeIconColor: AppColors.neutral100,
  );
}

SnackBar successSnackBar(String message) {
  return SnackBar(
    content: Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.successColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              color: AppColors.successColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
    duration: const Duration(seconds: 4),
    backgroundColor: AppColors.greenBg,
    showCloseIcon: true,
    closeIconColor: AppColors.neutral100,
  );
}

SnackBar waitingSnackbar(String message) {
  return SnackBar(
    content: Row(
      children: [
        const Icon(Icons.downloading, color: AppColors.warningColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              color: AppColors.warningColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
    duration: const Duration(seconds: 4),
    backgroundColor: AppColors.yellowBg,
    showCloseIcon: true,
    closeIconColor: AppColors.neutral100,
  );
}
