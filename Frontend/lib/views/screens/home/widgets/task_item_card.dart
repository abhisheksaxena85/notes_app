import 'package:flutter/material.dart';
import 'package:notes_app/data/network/dto/response/task/task_item.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';
import 'package:notes_app/views/screens/home/widgets/item_status_sheet.dart';
import 'package:notes_app/views/widgets/daymark_card.dart';
import 'package:notes_app/views/widgets/status_pill.dart';

/// A task on the Workspace (design/README.md §6). The 22 px checkbox is an
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
  final dot = Text('  ·  ', style: metaStyle);

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DaymarkCard(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      onTap: onTap,
      onLongPress: onStatusSelected == null
          ? null
          : () async {
              final selected = await showItemStatusSheet(
                context,
                currentStatus: task.status,
              );
              if (selected != null) onStatusSelected(selected);
            },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 22 px checkbox in a 44 px touch target.
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
                    width: 22,
                    height: 22,
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
                            child: AppIcons.icon(AppIcons.check, size: 14, color: palette.onAccent),
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
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DaymarkText.bodyStrong.copyWith(
                      color: isCompleted ? palette.muted : palette.ink,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: palette.muted,
                    ),
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 4,
                    children: [
                      if (hasDue) ...[
                        AppIcons.icon(AppIcons.clock, size: 14, color: palette.muted),
                        const SizedBox(width: 5),
                        Text(DisplayFormat.due(task.dueDate, task.dueTime), style: metaStyle),
                        dot,
                      ],
                      Text(category, style: metaStyle),
                      dot,
                      if (isCompleted)
                        Text(
                          'Done',
                          style: DaymarkText.custom(12.5, FontWeight.w500).copyWith(color: palette.success),
                        )
                      else if (high) ...[
                        AppIcons.icon(AppIcons.priority, size: 14, color: palette.danger),
                        const SizedBox(width: 4),
                        Text('High', style: metaStyle.copyWith(color: palette.danger)),
                      ] else
                        Text(StatusPill.labelFor(task.priority), style: metaStyle),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMissedOrRejected)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 6),
              child: StatusPill(StatusPill.labelFor(status)),
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
