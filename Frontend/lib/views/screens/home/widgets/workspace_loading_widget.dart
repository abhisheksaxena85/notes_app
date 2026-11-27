import 'package:flutter/material.dart';
import 'package:notes_app/views/screens/home/widgets/workspace_header.dart';
import 'package:notes_app/views/widgets/daymark_card.dart';
import 'package:notes_app/views/widgets/skeleton/skeleton.dart';

/// The Workspace while it loads (design/README.md §7): the header, stats,
/// search, chips, section headers and 2 task, 2 reminder and 1 note card
/// shapes. Cards keep their real surface and border; only their contents
/// shimmer.
class WorkspaceLoadingWidget extends StatelessWidget {
  const WorkspaceLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // Date line + greeting, avatar
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(widthFactor: 0.42, height: 11),
                    SizedBox(height: 10),
                    SkeletonLine(widthFactor: 0.72, height: 20),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonCircle(size: 44),
            ],
          ),
          const SizedBox(height: 18),
          // Stats
          Row(
            children: [
              for (final width in const [0.4, 0.55, 0.45]) ...[
                Expanded(
                  child: StatCard(
                    value: const SizedBox(
                      height: 20,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SkeletonBox(width: 22, height: 14, radius: 7),
                      ),
                    ),
                    label: SizedBox(height: 15, child: Center(child: SkeletonLine(widthFactor: width + 0.2, height: 10))),
                  ),
                ),
                if (width != 0.45) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // Search
          const SkeletonBox(height: 44, radius: 14),
          const SizedBox(height: 14),
          // Filter chips
          const Row(
            children: [
              SkeletonBox(width: 46, height: 34, radius: 17),
              SizedBox(width: 8),
              SkeletonBox(width: 70, height: 34, radius: 17),
              SizedBox(width: 8),
              SkeletonBox(width: 64, height: 34, radius: 17),
              SizedBox(width: 8),
              SkeletonBox(width: 96, height: 34, radius: 17),
            ],
          ),
          const SizedBox(height: 22),
          _sectionHeader(0.22),
          const _TaskShape(titleWidth: 0.7, metaWidth: 0.5),
          const _TaskShape(titleWidth: 0.55, metaWidth: 0.62),
          const SizedBox(height: 14),
          _sectionHeader(0.3),
          const _ReminderShape(titleWidth: 0.62, metaWidth: 0.4),
          const _ReminderShape(titleWidth: 0.48, metaWidth: 0.55),
          const SizedBox(height: 14),
          _sectionHeader(0.2),
          const _NoteShape(),
        ],
      ),
    );
  }

  static Widget _sectionHeader(double width) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 2),
        child: Row(
          children: [
            Expanded(child: SkeletonLine(widthFactor: width, height: 13)),
            const SkeletonBox(width: 44, height: 11, radius: 5.5),
          ],
        ),
      );
}

class _TaskShape extends StatelessWidget {
  const _TaskShape({required this.titleWidth, required this.metaWidth});

  final double titleWidth;
  final double metaWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DaymarkCard(
        padding: const EdgeInsets.fromLTRB(15, 15, 14, 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonCircle(size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  SkeletonLine(widthFactor: titleWidth, height: 13),
                  const SizedBox(height: 10),
                  SkeletonLine(widthFactor: metaWidth, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderShape extends StatelessWidget {
  const _ReminderShape({required this.titleWidth, required this.metaWidth});

  final double titleWidth;
  final double metaWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DaymarkCard(
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        child: Row(
          children: [
            const SkeletonBox(width: 36, height: 36, radius: 11),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(widthFactor: titleWidth, height: 13),
                  const SizedBox(height: 9),
                  SkeletonLine(widthFactor: metaWidth, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const SkeletonBox(width: 34, height: 10, radius: 5),
          ],
        ),
      ),
    );
  }
}

class _NoteShape extends StatelessWidget {
  const _NoteShape();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: DaymarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLine(widthFactor: 0.22, height: 10),
            SizedBox(height: 10),
            SkeletonLine(widthFactor: 0.6, height: 13),
            SizedBox(height: 10),
            SkeletonLine(widthFactor: 0.92, height: 10),
            SizedBox(height: 7),
            SkeletonLine(widthFactor: 0.68, height: 10),
            SizedBox(height: 12),
            Row(
              children: [
                SkeletonBox(width: 48, height: 20, radius: 7),
                SizedBox(width: 6),
                SkeletonBox(width: 60, height: 20, radius: 7),
                Spacer(),
                SkeletonBox(width: 40, height: 10, radius: 5),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
