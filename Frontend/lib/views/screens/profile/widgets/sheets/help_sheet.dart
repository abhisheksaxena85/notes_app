import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/sheet_scaffold.dart';

/// Profile → Help & FAQ.
void showHelpSheet(BuildContext context) {
  final palette = context.daymark;
  const faqs = [
    (
      "How does the Calendar count notes?",
      "Notes are counted strictly by their original creation date (createdAt). Editing a note never shifts its calendar timestamp.",
    ),
    (
      "How do offline notes work?",
      "When you are offline, new notes are stored locally in an encrypted Drift SQLite queue. When network connectivity resumes, the background sync service pushes them to the server.",
    ),
    (
      "Can I organize notes with tags?",
      "Yes! You can assign categories and custom tags to any note. Search searches across titles, content, categories, and tags.",
    ),
  ];
  showDaymarkSheet<void>(
    context,
    builder: (ctx) => SheetScaffold(
      title: "Help & FAQ",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < faqs.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, thickness: 1, color: palette.divider),
              ),
            _buildFaqItem(faqs[i].$1, faqs[i].$2, palette),
          ],
        ],
      ),
    ),
  );
}

Widget _buildFaqItem(String question, String answer, DaymarkPalette palette) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        question,
        style: DaymarkText.custom(14.5, FontWeight.w600).copyWith(color: palette.ink),
      ),
      const SizedBox(height: 4),
      Text(answer, style: DaymarkText.preview.copyWith(color: palette.inkSecondary)),
    ],
  );
}
