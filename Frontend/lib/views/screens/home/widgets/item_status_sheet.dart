import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/data/network/dto/response/item_status.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/widgets/sheet_scaffold.dart';

/// Long-press status picker for task and reminder cards. MISSED is derived
/// from the due time, so it is not offered as a manual choice. For a
/// [repeating] reminder it offers [RepeatingChoice]s instead.
Future<String?> showItemStatusSheet(
  BuildContext context, {
  required String currentStatus,
  bool repeating = false,
}) {
  final palette = context.daymark;
  final statusOptions = [
    (ItemStatus.pending, 'Pending', AppIcons.clock, palette.accent),
    (ItemStatus.completed, 'Completed', AppIcons.done, palette.success),
    (ItemStatus.rejected, 'Rejected', AppIcons.close, palette.danger),
  ];
  final repeatingOptions = [
    (RepeatingChoice.doneToday, 'Done for today', AppIcons.done, palette.success),
    (RepeatingChoice.missedToday, 'Missed today', AppIcons.close, palette.danger),
    (RepeatingChoice.stop, 'Stop repeating', AppIcons.repeat, palette.muted),
  ];
  final options = repeating ? repeatingOptions : statusOptions;

  return showDaymarkSheet<String>(
    context,
    builder: (sheetContext) => SheetScaffold(
      title: repeating ? 'This occurrence' : 'Status',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label, icon, color) in options)
            InkWell(
              onTap: () => Navigator.of(sheetContext).pop(value),
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    AppIcons.icon(icon, size: 20, color: color),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: DaymarkText.custom(14.5, FontWeight.w500).copyWith(color: palette.ink),
                      ),
                    ),
                    if (value == currentStatus)
                      AppIcons.icon(AppIcons.check, size: 18, color: palette.accent),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
