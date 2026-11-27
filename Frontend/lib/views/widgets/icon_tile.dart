import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';

/// A square tile holding one icon: settings rows (32), list rows (34),
/// reminder cards (36), the add menu (48). Defaults to the neutral `iconTile`
/// fill with an `inkSecondary` icon.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 32,
    this.radius = 10,
    this.iconSize,
    this.background,
    this.color,
  });

  /// An [AppIcons] asset path.
  final String icon;
  final double size;
  final double radius;
  final double? iconSize;
  final Color? background;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? palette.iconTile,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: AppIcons.icon(
        icon,
        size: iconSize ?? (size * 0.5).clamp(16, 22).toDouble(),
        color: color ?? palette.inkSecondary,
      ),
    );
  }
}
