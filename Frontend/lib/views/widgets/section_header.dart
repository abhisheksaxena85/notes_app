import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// "Tasks 3" with an optional "See all" link in `accent`.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.onSeeAll,
    this.actionLabel = 'See all',
  });

  final String title;
  final int? count;
  final VoidCallback? onSeeAll;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: title,
              style: DaymarkText.section.copyWith(color: palette.ink),
              children: [
                if (count != null)
                  TextSpan(
                    text: '  $count',
                    style: DaymarkText.custom(15, FontWeight.w500).copyWith(color: palette.muted),
                  ),
              ],
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 36),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: DaymarkText.custom(13, FontWeight.w500).copyWith(color: palette.accent),
            ),
          ),
      ],
    );
  }
}

/// An uppercase group label ("PREFERENCES", "TAGS").
class OverlineLabel extends StatelessWidget {
  const OverlineLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: DaymarkText.overline.copyWith(color: context.daymark.muted),
    );
  }
}
