/// @author Abhishek Saxena
/// Creation Date: 17-09-2025
/// Copyright © EL Nova Labs 2025. All rights reserved.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

Widget customTextInputField({
  required TextEditingController? controller,
  required String labelText,
  required bool isError,
  required String errorText,
  required Function(String value)? onChanged,
  required int? length,
  required List<TextInputFormatter> inputFormatters,
  required TextInputType keyboardType,
  Color? backgroundColor,
  bool? isEnabled,
  double? height,
  FocusNode? focusNode,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// MARK: Text Field
      SizedBox(
        height: height ?? 40.h,
        child: TextField(
          focusNode: focusNode,
          keyboardType: keyboardType,
          minLines: 1,
          maxLines: 100,
          enabled: isEnabled,
          scrollPadding: EdgeInsets.zero,
          onChanged: onChanged,
          maxLength: length,

          /// counter builder
          buildCounter: (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => null,
          controller: controller,

          /// Input formatters
          inputFormatters: inputFormatters,

          /// Input text style
          style: GoogleFonts.sourceSans3(
            fontSize: 14.sp,
            color: isEnabled == false
                ? AppColors.neutral70
                : AppColors.neutral100,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.start,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            fillColor: backgroundColor,
            filled: backgroundColor != null,

            /// Suffix error icon only
            suffixIcon: isError && inputFormatters.isNotEmpty
                ? Icon(Icons.error, color: AppColors.errorColor, size: 20.sp)
                : null,

            /// Content padding
            contentPadding: EdgeInsets.symmetric(
              vertical: 0.h,
              horizontal: 12.w,
            ),

            /// Label content
            labelText: labelText,
            labelStyle: GoogleFonts.sourceSans3(
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: isError ? AppColors.errorColor : null,
            ),

            /// Border styles
            enabledBorder: outlineInputBorder(
              isError ? AppColors.errorColor : AppColors.neutral60,
              false,
            ),
            focusedBorder: outlineInputBorder(
              isError ? AppColors.errorColor : AppColors.priBlue30,
              true,
            ),
            disabledBorder: outlineInputBorder(
              isError ? AppColors.errorColor : AppColors.neutral60,
              false,
            ),
          ),
        ),
      ),

      /// MARK: Error Text
      if (isError) ...[
        SizedBox(height: 4.h),
        Container(
          margin: EdgeInsets.only(left: 16.w),
          child: Text(
            errorText,
            style: GoogleFonts.sourceSans3(
              fontSize: 12.sp,
              color: AppColors.errorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ],
  );
}

/// Widget to build the outer border of text field
OutlineInputBorder outlineInputBorder(Color color, bool isFocused) {
  return OutlineInputBorder(
    borderSide: BorderSide(color: color, width: isFocused ? 1.4.w : 1.w),
    borderRadius: BorderRadius.circular(4.r),
  );
}
