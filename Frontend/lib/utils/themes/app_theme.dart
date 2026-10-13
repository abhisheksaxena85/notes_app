import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

class AppTheme {
  /// Full Application's default theme
  static ThemeData defaultAppTheme() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.bgColor,
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) {
          return Icon(Icons.arrow_back_sharp, color: AppColors.iconTextColor);
        },
        closeButtonIconBuilder: (context) {
          return Icon(Icons.close, color: AppColors.iconTextColor);
        },
      ),

      useMaterial3: true,
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
        alignment: Alignment.center,
        titleTextStyle: GoogleFonts.googleSans(
          color: AppColors.bgColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgColor,
        toolbarHeight: 0.h,
        surfaceTintColor: AppColors.bgColor,
      ),
    );
  }
}
