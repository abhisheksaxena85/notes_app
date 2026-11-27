import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/icon_tile.dart';

Widget notesErrorWidget({
  required String message,
  required VoidCallback onRetry,
}) {
  return Builder(
    builder: (context) {
      final palette = context.daymark;
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconTile(
              icon: AppIcons.info,
              size: 56,
              radius: 18,
              iconSize: 26,
              background: palette.dangerSoft,
              color: palette.danger,
            ),
            const SizedBox(height: 16),
            Text(
              "Unable to load your workspace",
              textAlign: TextAlign.center,
              style: DaymarkText.custom(17, FontWeight.w600).copyWith(color: palette.ink),
            ),
            const SizedBox(height: 6),
            Text(
              message.isNotEmpty
                  ? message
                  : "Something went wrong while fetching notes.",
              textAlign: TextAlign.center,
              style: DaymarkText.preview.copyWith(color: palette.muted),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: AppIcons.icon(AppIcons.sync, size: 18, color: palette.accent),
              label: Text(
                "Try again",
                style: DaymarkText.custom(14.5, FontWeight.w600).copyWith(color: palette.accent),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
          ],
        ),
      );
    },
  );
}
