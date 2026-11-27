import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/icon_tile.dart';

/// An empty or error state: a 56 px tile, a title, a message and an optional
/// outlined action ("Try again").
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.danger = false,
  });

  /// An [AppIcons] asset path.
  final String icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTile(
            icon: icon,
            size: 56,
            radius: 18,
            iconSize: 26,
            background: danger ? palette.dangerSoft : palette.accentSoft,
            color: danger ? palette.danger : palette.accent,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DaymarkText.custom(17, FontWeight.w600).copyWith(color: palette.ink),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DaymarkText.preview.copyWith(color: palette.muted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: AppIcons.icon(AppIcons.sync, size: 18, color: palette.accent),
              label: Text(
                actionLabel!,
                style: DaymarkText.custom(14.5, FontWeight.w600).copyWith(color: palette.accent),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
