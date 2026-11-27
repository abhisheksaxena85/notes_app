import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

enum DaymarkChipStyle {
  /// Workspace filters (All / Notes / …): 34 high, `ink` fill when selected.
  filter,

  /// Category pickers: 32 high, `accentSoft` fill and `accent` border when
  /// selected.
  category,
}

/// A pill chip (design/README.md §6).
class DaymarkChip extends StatelessWidget {
  const DaymarkChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.style = DaymarkChipStyle.filter,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final DaymarkChipStyle style;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final isFilter = style == DaymarkChipStyle.filter;
    final height = isFilter ? 34.0 : 32.0;

    final Color fill;
    final Color text;
    final Color border;
    if (!selected) {
      fill = Colors.transparent;
      text = palette.inkSecondary;
      border = palette.chipBorder;
    } else if (isFilter) {
      fill = palette.ink;
      text = palette.background;
      border = palette.ink;
    } else {
      fill = palette.accentSoft;
      text = palette.accent;
      border = palette.accent;
    }

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: height,
          padding: EdgeInsets.symmetric(horizontal: isFilter ? 15 : 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: DaymarkText.chip(selected: selected).copyWith(color: text),
          ),
        ),
      ),
    );
  }
}

/// A horizontally scrolling row of category chips (note editor, task and
/// reminder sheets).
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final category in categories) ...[
            DaymarkChip(
              label: category,
              selected: category == selected,
              style: DaymarkChipStyle.category,
              onTap: () => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
