import 'package:flutter/material.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/screens/home/widgets/item_status_sheet.dart';
import 'package:notes_app/views/widgets/daymark_card.dart';
import 'package:notes_app/views/widgets/status_pill.dart';

/// A task on the Workspace (design/README.md §6). The 24 px checkbox is an
/// `accent` ring when pending, a `success` fill when completed and a `danger`
/// ring plus a Missed / Rejected pill when missed or rejected.
Widget taskItemCard({
  required BuildContext context,
  required TaskItem task,
  required ValueChanged<bool> onToggleComplete,
  VoidCallback? onTap,
  VoidCallback? onDelete,
  ValueChanged<String>? onStatusSelected,
}) {
  final palette = context.daymark;
  final String status = task.effectiveStatus();
  final bool isCompleted = status == 'COMPLETED';
  final bool isMissedOrRejected = status == 'MISSED' || status == 'REJECTED';

  final String title = task.title.trim().isNotEmpty ? task.title : "Untitled Task";
  final String description = task.description ?? "";
  final String category = (task.category != null && task.category!.trim().isNotEmpty)
      ? task.category!
      : "General";
  final bool hasDue = (task.dueDate?.isNotEmpty ?? false) || (task.dueTime?.isNotEmpty ?? false);
  final bool high = task.priority == 'HIGH';
  final metaStyle = DaymarkText.meta.copyWith(color: palette.muted);
  const dot = TextSpan(text: '\u00A0\u00A0·  ');

  return Padding(
    padding: const EdgeInsets.only(bottom: DaymarkCard.gap),
    child: DaymarkCard(
      // 16 to the checkbox ring (6 + the 44 px target's 10) and to the text
      // (7 + 9).
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
      onTap: onTap,
      onLongPress: onStatusSelected == null
          ? null
          : () async {
              final selected = await showItemStatusSheet(
                context,
                currentStatus: task.status,
                canDelete: onDelete != null,
              );
              if (selected == deleteItemChoice) {
                onDelete?.call();
              } else if (selected != null) {
                onStatusSelected(selected);
              }
            },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 24 px checkbox in a 44 px touch target.
          Semantics(
            checked: isCompleted,
            label: isCompleted ? 'Mark as not done' : 'Mark as done',
            button: true,
            child: GestureDetector(
              onTap: () => onToggleComplete(!isCompleted),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? palette.success : Colors.transparent,
                      border: isCompleted
                          ? null
                          : Border.all(
                              color: isMissedOrRejected ? palette.danger : palette.accent,
                              width: 1.6,
                            ),
                    ),
                    child: isCompleted
                        ? Center(
                            child: AppIcons.icon(AppIcons.check, size: 15, color: palette.onAccent),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 9, bottom: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DaymarkText.bodyStrong.copyWith(
                            color: isCompleted ? palette.muted : palette.ink,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: palette.muted,
                          ),
                        ),
                      ),
                      if (isMissedOrRejected) ...[
                        const SizedBox(width: 8),
                        StatusPill(StatusPill.labelFor(status)),
                      ],
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DaymarkText.preview.copyWith(
                        color: isCompleted ? palette.muted : palette.inkSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      style: metaStyle,
                      children: [
                        if (hasDue) ...[
                          _iconSpan(AppIcons.clock, palette.muted),
                          TextSpan(text: DisplayFormat.due(task.dueDate, task.dueTime)),
                          dot,
                        ],
                        TextSpan(text: category),
                        dot,
                        if (isCompleted)
                          TextSpan(
                            text: 'Done',
                            style: TextStyle(color: palette.success, fontWeight: FontWeight.w500),
                          )
                        else if (high) ...[
                          _iconSpan(AppIcons.priority, palette.danger),
                          TextSpan(text: 'High', style: TextStyle(color: palette.danger)),
                        ] else
                          TextSpan(text: StatusPill.labelFor(task.priority)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onDelete != null)
            CardIconButton(
              icon: AppIcons.icon(AppIcons.delete, size: 18, color: palette.muted),
              tooltip: 'Delete',
              onPressed: onDelete,
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    ),
  );
}

/// A 14 px icon inline with meta text.
InlineSpan _iconSpan(String icon, Color color) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.only(right: 5),
        child: AppIcons.icon(icon, size: 14, color: color),
      ),
    );
