import 'package:flutter/material.dart';
import 'package:notes_app/views/widgets/daymark_card.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/date/display_format.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// Date line, time-of-day greeting and the avatar that opens Profile.
class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.userName,
    this.onAvatarTap,
    this.now,
  });

  final String? userName;
  final VoidCallback? onAvatarTap;

  /// For tests; defaults to the current time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final time = now ?? DateTime.now();
    final name = userName?.trim() ?? '';
    final firstName = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    final greeting = DisplayFormat.greeting(time);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DisplayFormat.longDate(time),
                style: DaymarkText.meta.copyWith(color: palette.muted),
              ),
              const SizedBox(height: 4),
              Text(
                firstName.isEmpty ? greeting : '$greeting, $firstName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DaymarkText.title.copyWith(color: palette.ink),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        UserAvatar(name: name, size: 44, onTap: onAvatarTap, semanticLabel: 'Open profile'),
      ],
    );
  }
}

/// A circle avatar: `accentSoft` fill with the initials in `accent`.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.onTap,
    this.semanticLabel,
  });

  final String? name;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final initials = DisplayFormat.initials(name);
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: palette.accentSoft, shape: BoxShape.circle),
      child: initials.isEmpty
          ? AppIcons.icon(AppIcons.profile, size: size * 0.45, color: palette.accent)
          : Text(
              initials,
              style: DaymarkText.custom(size * 0.36, FontWeight.w600).copyWith(color: palette.accent),
            ),
    );
    if (onTap == null) return avatar;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: avatar),
    );
  }
}

/// One of the three stat cards: a number over a label.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.value, required this.label});

  /// Usually a number; a widget so loading states can shimmer it.
  final Widget value;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    // The shared card style, a little tighter than item cards.
    return DaymarkCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [value, const SizedBox(height: 2), label],
      ),
    );
  }
}

/// The stats row: tasks today, reminders, notes.
class WorkspaceStats extends StatelessWidget {
  const WorkspaceStats({
    super.key,
    required this.tasksToday,
    required this.reminders,
    required this.notes,
  });

  final int tasksToday;
  final int reminders;
  final int notes;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    Widget stat(int value, String label) => Expanded(
          child: StatCard(
            value: Text(
              '$value',
              style: DaymarkText.custom(16, FontWeight.w600).copyWith(color: palette.ink),
            ),
            label: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DaymarkText.custom(12, FontWeight.w400).copyWith(color: palette.muted),
            ),
          ),
        );
    return Row(
      children: [
        stat(tasksToday, 'tasks today'),
        const SizedBox(width: DaymarkCard.gap),
        stat(reminders, 'reminders'),
        const SizedBox(width: DaymarkCard.gap),
        stat(notes, 'notes'),
      ],
    );
  }
}

/// The 44 px search field on `surfaceMuted`.
class WorkspaceSearchField extends StatelessWidget {
  const WorkspaceSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        children: [
          AppIcons.icon(AppIcons.search, size: 18, color: palette.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: DaymarkText.custom(14.5, FontWeight.w400).copyWith(color: palette.ink),
              decoration: InputDecoration(
                hintText: 'Search notes, tasks, reminders',
                hintStyle: DaymarkText.custom(14.5, FontWeight.w400).copyWith(color: palette.muted),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              tooltip: 'Clear search',
              icon: AppIcons.icon(AppIcons.close, size: 18, color: palette.muted),
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              padding: EdgeInsets.zero,
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}
