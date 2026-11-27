import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/views/screens/note_details/widgets/build_note_form_widget.dart';
import 'package:notes_app/views/screens/note_details/widgets/note_details_app_bar.dart';
import 'package:notes_app/views/widgets/primary_button.dart';
import 'package:notes_app/views/widgets/skeleton/skeleton.dart';

/// The note editor while a note loads (design/README.md §7): the back button
/// and title are real, pin and more are 28 px blocks; the title, meta,
/// category chips, body paragraphs and tag chips shimmer. Save is disabled
/// and delete is greyed out.
class NoteDetailsLoadingWidget extends StatelessWidget {
  const NoteDetailsLoadingWidget({super.key, this.isEditMode = true});

  final bool isEditMode;

  /// Body line widths, grouped in paragraphs.
  static const _paragraphs = [
    [0.94, 0.88, 0.91, 0.52],
    [0.9, 0.96, 0.7],
    [0.86, 0.6],
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return Shimmer(
      child: Column(
        children: [
          noteDetailsAppBar(
            context: context,
            isEditMode: isEditMode,
            isPinned: false,
            onTogglePin: null,
            pinSlot: const Padding(
              padding: EdgeInsets.all(8),
              child: SkeletonBox(width: 28, height: 28, radius: 8),
            ),
            moreSlot: const Padding(
              padding: EdgeInsets.all(8),
              child: SkeletonBox(width: 28, height: 28, radius: 8),
            ),
          ),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              children: [
                const SkeletonLine(widthFactor: 0.72, height: 26),
                const SizedBox(height: 14),
                const SkeletonLine(widthFactor: 0.45, height: 11),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    SkeletonBox(width: 72, height: 32, radius: 16),
                    SizedBox(width: 8),
                    SkeletonBox(width: 56, height: 32, radius: 16),
                    SizedBox(width: 8),
                    SkeletonBox(width: 80, height: 32, radius: 16),
                    SizedBox(width: 8),
                    SkeletonBox(width: 64, height: 32, radius: 16),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, thickness: 1, color: palette.divider),
                const SizedBox(height: 20),
                for (final paragraph in _paragraphs) ...[
                  for (final width in paragraph) ...[
                    SkeletonLine(widthFactor: width, height: 12),
                    const SizedBox(height: 13),
                  ],
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                const SkeletonLine(widthFactor: 0.14, height: 10),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    SkeletonBox(width: 64, height: 30, radius: 9),
                    SizedBox(width: 8),
                    SkeletonBox(width: 84, height: 30, radius: 9),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: palette.background,
              border: Border(top: BorderSide(color: palette.line)),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
            child: Row(
              children: [
                if (isEditMode) ...[
                  noteDeleteButton(context),
                  const SizedBox(width: 10),
                ],
                const Expanded(child: PrimaryButton(label: "Save note", onPressed: null)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget noteDetailsLoadingWidget({bool isEditMode = true}) =>
    NoteDetailsLoadingWidget(isEditMode: isEditMode);
