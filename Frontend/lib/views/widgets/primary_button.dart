import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// The 52 px accent button (design/README.md §6). A null [onPressed] shows
/// the disabled colours; [loading] shows a small spinner and ignores taps.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;

  /// An optional leading [AppIcons] asset path.
  final String? icon;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final enabled = onPressed != null && !loading;
    final fg = onPressed != null ? palette.onAccent : palette.onButtonDisabled;
    return Semantics(
      button: true,
      enabled: enabled,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Material(
          color: onPressed != null ? palette.accent : palette.buttonDisabled,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          AppIcons.icon(icon!, size: 18, color: fg),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DaymarkText.button.copyWith(color: fg),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An outlined button on `surface` (Sign out, Not done, Snooze, Edit). Pass
/// [color] for the text and icon and [borderColor] for the outline.
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.borderColor,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final Color? color;
  final Color? borderColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final fg = onPressed == null ? palette.disabled : (color ?? palette.ink);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor ?? palette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  AppIcons.icon(icon!, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DaymarkText.custom(14.5, FontWeight.w600).copyWith(color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
