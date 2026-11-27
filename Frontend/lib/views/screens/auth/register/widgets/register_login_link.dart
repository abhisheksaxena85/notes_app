import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

Widget registerLoginLink({
  required BuildContext context,
}) {
  final palette = context.daymark;
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Already have an account?",
        style: DaymarkText.custom(13.5, FontWeight.w400).copyWith(color: palette.muted),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(
          "Sign in",
          style: DaymarkText.custom(13.5, FontWeight.w600).copyWith(color: palette.accent),
        ),
      ),
    ],
  );
}
