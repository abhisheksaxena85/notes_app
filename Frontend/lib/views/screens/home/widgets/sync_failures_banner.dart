import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/data/local/database/sync_queue_models.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/viewmodel/controllers.dart';

/// "N items couldn't sync" with a way to retry or discard them. Hidden when
/// every queued change was accepted.
class SyncFailuresBanner extends ConsumerWidget {
  const SyncFailuresBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failures = ref.watch(syncStatusController).value ?? const [];
    if (failures.isEmpty) return const SizedBox.shrink();

    final palette = context.daymark;
    final count = failures.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 14.h),
      child: Material(
        color: palette.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => showSyncFailuresSheet(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: palette.danger.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, size: 18.sp, color: palette.danger),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    count == 1
                        ? "1 item couldn't sync"
                        : "$count items couldn't sync",
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                ),
                Text(
                  'Review',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showSyncFailuresSheet(BuildContext context) {
  final palette = context.daymark;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: palette.surface,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final failures = ref.watch(syncStatusController).value ?? const [];
        final notifier = ref.read(syncStatusController.notifier);
        if (failures.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (sheetContext.mounted) Navigator.of(sheetContext).maybePop();
          });
        }
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 0.7.sh),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 18.h, 12.w, 4.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Couldn't sync",
                          style: GoogleFonts.inter(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      if (failures.length > 1)
                        TextButton(
                          onPressed: notifier.retryAll,
                          child: Text(
                            'Retry all',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: palette.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    'The server refused these changes. Retry after fixing the '
                    'problem, or discard them to remove them from this device.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: palette.muted,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final failure in failures)
                        _SyncFailureTile(
                          failure: failure,
                          onRetry: () => notifier.retry(failure),
                          onDiscard: () async {
                            if (await _confirmDiscard(context, failure)) {
                              await notifier.discard(failure);
                            }
                          },
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<bool> _confirmDiscard(BuildContext context, SyncFailure failure) async {
  final palette = context.daymark;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: palette.line),
      ),
      title: Text(
        'Discard this change?',
        style: GoogleFonts.inter(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
      ),
      content: Text(
        failure.operation == 'create'
            ? '"${failure.title}" was never saved to the server. Discarding '
                'removes it from this device too.'
            : 'Your change to "${failure.title}" will be dropped and the '
                "server's version shown again after the next refresh.",
        style: GoogleFonts.inter(fontSize: 13.sp, color: palette.muted, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('Cancel', style: GoogleFonts.inter(color: palette.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            'Discard',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: palette.danger,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _SyncFailureTile extends StatelessWidget {
  final SyncFailure failure;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  const _SyncFailureTile({
    required this.failure,
    required this.onRetry,
    required this.onDiscard,
  });

  String get _kind {
    final kind = switch (failure.entity) {
      SyncEntity.note => 'Note',
      SyncEntity.task => 'Task',
      SyncEntity.reminder => 'Reminder',
    };
    final change = switch (failure.operation) {
      'create' => 'new',
      'status' => 'status change',
      'delete' => 'delete',
      _ => 'edit',
    };
    return '$kind $change';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return ListTile(
      contentPadding: EdgeInsets.only(left: 20.w, right: 8.w),
      title: Text(
        failure.title.isEmpty ? 'Untitled' : failure.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: palette.ink,
        ),
      ),
      subtitle: Text(
        '$_kind · ${failure.lastError ?? 'Refused by the server'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: 12.sp, color: palette.muted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Retry',
            icon: AppIcons.icon(AppIcons.sync, color: palette.accent),
            onPressed: onRetry,
          ),
          IconButton(
            tooltip: 'Discard',
            icon: AppIcons.icon(AppIcons.delete, color: palette.danger),
            onPressed: onDiscard,
          ),
        ],
      ),
    );
  }
}
