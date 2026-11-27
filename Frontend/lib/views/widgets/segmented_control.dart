import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// A `surfaceMuted` track with equal segments; the selected one is `surface`
/// with a tiny shadow (Month / Week, the Repeat picker).
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.height = 36,
    this.expand = true,
  });

  /// Value → label, in display order.
  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  /// Fill the available width. When false each segment sizes to its label.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final children = [
      for (final entry in segments.entries)
        _segment(context, palette, entry.key, entry.value),
    ];
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: expand ? [for (final c in children) Expanded(child: c)] : children,
      ),
    );
  }

  Widget _segment(BuildContext context, DaymarkPalette palette, T key, String label) {
    final selected = key == value;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? palette.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: palette.isDark ? 0.3 : 0.08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            style: DaymarkText.chip(selected: selected).copyWith(
              color: selected ? palette.ink : palette.muted,
            ),
          ),
        ),
      ),
    );
  }
}
