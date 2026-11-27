import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// FIX-01: the one confirmation dialog for destructive (and other) actions.
/// True only when the confirm button is pressed; Cancel, back and a tap
/// outside all answer false.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    // A tap outside (and back) cancels.
    barrierDismissible: true,
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return confirmed ?? false;
}

/// "Delete reminder?" / "“Call mom” will be permanently deleted." / "Delete".
/// [kind] is "note", "task" or "reminder"; [repeating] adds that a repeating
/// reminder stops for good.
Future<bool> confirmDelete(
  BuildContext context, {
  required String kind,
  required String itemTitle,
  bool repeating = false,
}) {
  final name = itemTitle.trim();
  final subject = name.isEmpty ? 'This $kind' : '“$name”';
  final stops = repeating ? ' This stops all future reminders.' : '';
  return showConfirmDialog(
    context,
    title: 'Delete $kind?',
    message: '$subject will be permanently deleted.$stops',
    confirmLabel: 'Delete',
  );
}

/// Asked when leaving an editor or form with unsaved edits.
Future<bool> confirmDiscardChanges(BuildContext context) => showConfirmDialog(
      context,
      title: 'Discard changes?',
      message: "Your changes haven't been saved and will be lost.",
      confirmLabel: 'Discard',
    );

/// The plain snackbar after a confirmed delete ("Reminder deleted"): no Undo,
/// the dialog already asked.
SnackBar deletedSnackBar(String kind) =>
    SnackBar(content: Text('${kind[0].toUpperCase()}${kind.substring(1)} deleted'));

/// Design tokens: `surface`, radius 20, title 17/600 `ink`, message 14/400
/// `muted`, a Cancel text button (`inkSecondary`, focused first) and the
/// confirm button (`danger` fill when [destructive], otherwise `accent`, with
/// `onAccent` text).
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.destructive = true,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final fill = destructive ? palette.danger : palette.accent;
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return Dialog(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: DaymarkText.custom(17, FontWeight.w600).copyWith(color: palette.ink),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    message,
                    style: DaymarkText.custom(14, FontWeight.w400, height: 1.45)
                        .copyWith(color: palette.muted),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      // The safe choice has the initial focus.
                      autofocus: true,
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.inkSecondary,
                        minimumSize: const Size(64, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: buttonShape,
                        textStyle: DaymarkText.custom(15, FontWeight.w600),
                      ),
                      child: Text(cancelLabel),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: fill,
                        foregroundColor: palette.onAccent,
                        minimumSize: const Size(64, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: buttonShape,
                        elevation: 0,
                        textStyle: DaymarkText.custom(15, FontWeight.w600),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
