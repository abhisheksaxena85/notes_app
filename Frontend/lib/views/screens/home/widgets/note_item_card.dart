import 'package:flutter/material.dart';
import 'package:notes_app/data/network/dto/response/home/get_all_notes_response_dto.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/date/date_keys.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/daymark_card.dart';

/// A note on the Workspace (design/README.md §6): category overline with the
/// pin, title, a two-line preview, then tag chips and the relative time.
Widget noteItemCard({
  required BuildContext context,
  required NoteItem note,
  VoidCallback? onTap,
}) {
  final palette = context.daymark;
  final bool isPinned = note.pinned ?? false;
  final String title = (note.title != null && note.title!.trim().isNotEmpty)
      ? note.title!
      : "Untitled Note";
  final String content = note.content ?? "";
  final String category = (note.category != null && note.category!.trim().isNotEmpty)
      ? note.category!
      : "General";
  final tags = note.tagsList
      .where((t) => t.toLowerCase() != category.toLowerCase())
      .toList();
  final String dateText = _formatDate(note.updatedAt ?? note.createdAt);

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DaymarkCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DaymarkText.custom(12, FontWeight.w500).copyWith(color: palette.muted),
                ),
              ),
              if (isPinned)
                Semantics(
                  label: 'Pinned',
                  child: AppIcons.icon(AppIcons.pin, size: 14, color: palette.accent),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DaymarkText.custom(15, FontWeight.w600).copyWith(color: palette.ink),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DaymarkText.preview.copyWith(color: palette.inkSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final tag in tags) _TagChip(tag)],
                ),
              ),
              const SizedBox(width: 8),
              Text(dateText, style: DaymarkText.meta.copyWith(color: palette.muted)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.tag);

  final String tag;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.tagFill,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        tag,
        style: DaymarkText.custom(12, FontWeight.w500).copyWith(color: palette.inkSecondary),
      ),
    );
  }
}

String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return "Recently";
  final parsed = DateKeys.instant(dateStr);
  if (parsed == null) return dateStr;
  return DisplayFormat.relative(parsed);
}
