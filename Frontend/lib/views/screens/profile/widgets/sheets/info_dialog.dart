import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// The title + message dialog used by About and Privacy & security.
void showInfoDialog(BuildContext context, String title, String message) {
  final palette = context.daymark;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message, style: DaymarkText.preview.copyWith(color: palette.inkSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            "OK",
            style: DaymarkText.custom(14, FontWeight.w600).copyWith(color: palette.accent),
          ),
        ),
      ],
    ),
  );
}
