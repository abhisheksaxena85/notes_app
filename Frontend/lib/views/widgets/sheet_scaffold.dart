import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// Opens a Daymark bottom sheet: `surface`, 26 top radius, on the scrim, with
/// the keyboard pushing it up.
Future<T?> showDaymarkSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: builder,
  );
}

/// The body of a bottom sheet: a 40×4 handle, the [title] and a 40 px close
/// button, then [child]. [footer] stays pinned below the scrolling content
/// (usually a [PrimaryButton]).
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.child,
    this.title,
    this.footer,
    this.actions = const [],
    this.onClose,
    this.showClose = true,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 0),
  });

  final String? title;
  final Widget child;
  final Widget? footer;

  /// Extra header buttons shown before the close button (e.g. delete).
  final List<Widget> actions;

  /// Defaults to popping the sheet.
  final VoidCallback? onClose;
  final bool showClose;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _build(context, constraints.hasBoundedHeight),
    );
  }

  Widget _build(BuildContext context, bool bounded) {
    final palette = context.daymark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.chipBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (title != null || showClose)
            Padding(
              padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right - 2, 4),
              child: Row(
                children: [
                  Expanded(
                    child: title == null
                        ? const SizedBox.shrink()
                        : Text(
                            title!,
                            style: DaymarkText.sheetTitle.copyWith(color: palette.ink),
                          ),
                  ),
                  ...actions,
                  if (showClose) SheetCloseButton(onPressed: onClose),
                ],
              ),
            )
          else
            const SizedBox(height: 12),
          if (bounded)
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 16),
                child: child,
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 16),
              child: child,
            ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(padding.left, 4, padding.right, 16 + (bottomInset > 0 ? 0 : bottomSafe)),
              child: footer,
            )
          else
            SizedBox(height: bottomInset > 0 ? 0 : bottomSafe),
        ],
      ),
    );
  }
}

/// The 40 px `iconTile` close button with a 44 px touch target.
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return Semantics(
      button: true,
      label: 'Close',
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Material(
            color: palette.iconTile,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed ?? () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: AppIcons.icon(AppIcons.close, size: 18, color: palette.inkSecondary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
