import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/date/date_keys.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// "Created 24 Nov · Edited 2h ago".
Widget noteMetaInfoWidget({
  String? createdAt,
  String? updatedAt,
}) {
  final created = DateKeys.instant(createdAt);
  final updated = DateKeys.instant(updatedAt);
  if (created == null && updated == null) return const SizedBox.shrink();

  final parts = [
    if (created != null) 'Created ${DisplayFormat.shortDate(created)}',
    if (updated != null) 'Edited ${DisplayFormat.relative(updated).replaceFirst('Just now', 'just now')}',
  ];

  return Builder(
    builder: (context) => Text(
      parts.join(' · '),
      style: DaymarkText.meta.copyWith(color: context.daymark.muted),
    ),
  );
}
