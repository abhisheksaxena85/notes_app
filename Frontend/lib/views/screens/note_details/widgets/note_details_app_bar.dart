import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// The editor's top bar: back, "Edit note" / "New note", pin and more.
/// [pinSlot] and [moreSlot] replace the pin and more buttons (loading state).
Widget noteDetailsAppBar({
  required BuildContext context,
  required bool isEditMode,
  required bool isPinned,
  required VoidCallback? onTogglePin,
  VoidCallback? onMore,
  Widget? pinSlot,
  Widget? moreSlot,
}) {
  final palette = context.daymark;

  return SizedBox(
    height: 56,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
            icon: AppIcons.icon(AppIcons.back, size: 20, color: palette.ink),
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              isEditMode ? "Edit note" : "New note",
              style: DaymarkText.custom(15, FontWeight.w600).copyWith(color: palette.ink),
            ),
          ),
          pinSlot ??
              Semantics(
                toggled: isPinned,
                child: IconButton(
                  onPressed: onTogglePin,
                  tooltip: isPinned ? 'Unpin' : 'Pin',
                  style: IconButton.styleFrom(
                    backgroundColor: isPinned
                        ? palette.accent.withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  icon: AppIcons.icon(AppIcons.pin, size: 20, color: palette.accent),
                  constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                ),
              ),
          if (moreSlot != null)
            moreSlot
          else if (onMore != null)
            IconButton(
              onPressed: onMore,
              tooltip: 'More',
              icon: AppIcons.icon(AppIcons.more, size: 20, color: palette.ink),
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
        ],
      ),
    ),
  );
}
