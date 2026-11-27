import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/views/widgets/daymark_card.dart';
import 'package:notes_app/views/widgets/skeleton/skeleton.dart';

/// Calendar loading pieces (design/README.md §7). The title, segmented
/// control, month name and date grid stay real; only the count badges, the
/// "N items" count and the day list shimmer. The screen wraps itself in a
/// [Shimmer] while loading and uses these in place of the real parts.

/// A 16×8 bar where a day's count badge goes.
class CalendarBadgeSkeleton extends StatelessWidget {
  const CalendarBadgeSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const SkeletonBox(width: 16, height: 8, radius: 4);
}

/// The "N items" count.
class CalendarCountSkeleton extends StatelessWidget {
  const CalendarCountSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const SkeletonBox(width: 44, height: 11, radius: 5.5);
}

/// The day list: one grouped card with 4 rows of a 34 px tile and 2 bars.
class CalendarDayListSkeleton extends StatelessWidget {
  const CalendarDayListSkeleton({super.key});

  static const _rows = [(0.62, 0.3), (0.48, 0.36), (0.7, 0.26), (0.55, 0.33)];

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return DaymarkCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < _rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: 60, color: palette.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 14, 11),
              child: Row(
                children: [
                  const SkeletonBox(width: 34, height: 34, radius: 10),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(widthFactor: _rows[i].$1, height: 12),
                        const SizedBox(height: 8),
                        SkeletonLine(widthFactor: _rows[i].$2, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
