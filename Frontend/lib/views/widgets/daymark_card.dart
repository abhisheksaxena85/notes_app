import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

/// A `surface` card with a 1 px border and no shadow (design/README.md §3).
class DaymarkCard extends StatelessWidget {
  const DaymarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    this.radius = 16,
    this.color,
    this.borderColor,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// 16 for item cards, 20 for large cards (month grid, profile card).
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? palette.cardBorder),
    );
    final content = Padding(padding: padding, child: child);
    return Material(
      color: color ?? palette.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null && onLongPress == null
          ? content
          : InkWell(onTap: onTap, onLongPress: onLongPress, child: content),
    );
  }
}
