/// @author Abhishek Saxena
/// Creation Date: 19-09-2025
/// Copyright © EL Nova Labs 2025. All rights reserved.
library;

import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// Snackbars are built without a BuildContext, so the colours are resolved
/// when the content builds. The background, shape and close icon come from
/// the theme's SnackBarThemeData.
SnackBar _statusSnackBar(
  String message, {
  required IconData icon,
  required Color Function(DaymarkPalette palette) iconColor,
}) {
  return SnackBar(
    content: Builder(
      builder: (context) {
        final palette = context.daymark;
        return Row(
          children: [
            Icon(icon, size: 20, color: iconColor(palette)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: DaymarkText.custom(14, FontWeight.w500).copyWith(
                  color: palette.background,
                ),
              ),
            ),
          ],
        );
      },
    ),
    duration: const Duration(seconds: 4),
    showCloseIcon: true,
  );
}

// Status icons on the inverted (ink) snackbar use the dark/light opposite
// palette so they keep contrast.
DaymarkPalette _inverse(DaymarkPalette palette) =>
    palette.isDark ? DaymarkPalette.light : DaymarkPalette.dark;

SnackBar failedSnackBar(String message) => _statusSnackBar(
      message,
      icon: Icons.error_outline_rounded,
      iconColor: (palette) => _inverse(palette).danger,
    );

SnackBar successSnackBar(String message) => _statusSnackBar(
      message,
      icon: Icons.check_circle_outline_rounded,
      iconColor: (palette) => _inverse(palette).success,
    );

SnackBar waitingSnackbar(String message) => _statusSnackBar(
      message,
      icon: Icons.downloading_rounded,
      iconColor: (palette) => _inverse(palette).accent,
    );
