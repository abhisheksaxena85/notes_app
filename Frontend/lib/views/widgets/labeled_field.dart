import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// A `label` above a form control, with an optional error line below.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
  });

  final String label;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final error = errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: DaymarkText.label.copyWith(color: palette.inkSecondary)),
        const SizedBox(height: 7),
        child,
        if (error != null && error.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(error, style: DaymarkText.meta.copyWith(color: palette.danger)),
        ],
      ],
    );
  }
}

/// A 48 px tappable field showing a value with a leading `accent` icon, for
/// date and time pickers.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.icon,
    required this.value,
    required this.onTap,
    this.placeholder = false,
  });

  /// An [AppIcons] asset path.
  final String icon;
  final String value;
  final VoidCallback onTap;

  /// Show [value] in `muted` (nothing picked yet).
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return Material(
      color: palette.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                AppIcons.icon(icon, size: 18, color: palette.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DaymarkText.custom(15, FontWeight.w400).copyWith(
                      color: placeholder ? palette.muted : palette.ink,
                    ),
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
