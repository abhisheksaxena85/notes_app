import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Daymark icon set (design/README.md §4): 24 px grid, 1.6 stroke, drawn
/// in currentColor so [AppIcons.icon] can tint them.
///
/// Sizes: 20 in the nav and top bars, 18 in cards and fields, 14 inline with
/// meta text, 22–24 in the FAB.
class AppIcons {
  const AppIcons._();

  static const String _dir = 'assets/icons';

  // Navigation and item types
  static const String workspace = '$_dir/ic_workspace.svg';
  static const String calendar = '$_dir/ic_calendar.svg';
  static const String profile = '$_dir/ic_profile.svg';
  static const String note = '$_dir/ic_note.svg';
  static const String task = '$_dir/ic_task.svg';
  static const String reminder = '$_dir/ic_reminder.svg';

  // Actions
  static const String plus = '$_dir/ic_plus.svg';
  static const String close = '$_dir/ic_close.svg';
  static const String check = '$_dir/ic_check.svg';
  static const String done = '$_dir/ic_done.svg';
  static const String edit = '$_dir/ic_edit.svg';
  static const String delete = '$_dir/ic_delete.svg';
  static const String search = '$_dir/ic_search.svg';
  static const String filter = '$_dir/ic_filter.svg';
  static const String pin = '$_dir/ic_pin.svg';
  static const String open = '$_dir/ic_open.svg';
  static const String more = '$_dir/ic_more.svg';
  static const String snooze = '$_dir/ic_snooze.svg';
  static const String sync = '$_dir/ic_sync.svg';
  static const String export = '$_dir/ic_export.svg';
  static const String import = '$_dir/ic_import.svg';
  static const String signOut = '$_dir/ic_sign_out.svg';

  // Attributes
  static const String clock = '$_dir/ic_clock.svg';
  static const String repeat = '$_dir/ic_repeat.svg';
  static const String priority = '$_dir/ic_priority.svg';
  static const String tag = '$_dir/ic_tag.svg';
  static const String category = '$_dir/ic_category.svg';

  // Settings
  static const String darkMode = '$_dir/ic_dark_mode.svg';
  static const String lightMode = '$_dir/ic_light_mode.svg';
  static const String preferences = '$_dir/ic_preferences.svg';
  static const String privacy = '$_dir/ic_privacy.svg';
  static const String backup = '$_dir/ic_backup.svg';
  static const String help = '$_dir/ic_help.svg';
  static const String info = '$_dir/ic_info.svg';
  static const String email = '$_dir/ic_email.svg';
  static const String password = '$_dir/ic_password.svg';
  static const String show = '$_dir/ic_show.svg';

  // Arrows
  static const String back = '$_dir/ic_back.svg';
  static const String forward = '$_dir/ic_forward.svg';
  static const String expand = '$_dir/ic_expand.svg';

  /// The app icon tile, used on the splash and login screens. Not tinted.
  static const String logoMark = '$_dir/logo_mark.svg';

  /// A tinted icon. Without [color] or [size] it follows the ambient
  /// [IconTheme], like a Material [Icon].
  static Widget icon(
    String assetPath, {
    Color? color,
    double? size,
    double? width,
    double? height,
    String? semanticLabel,
  }) {
    return DaymarkIcon(
      assetPath,
      color: color,
      size: size,
      width: width,
      height: height,
      semanticLabel: semanticLabel,
    );
  }

  /// [logoMark] at [size] (56 on login, larger on splash).
  static Widget logo({double size = 56}) {
    return SvgPicture.asset(
      logoMark,
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}

/// An SVG icon from [AppIcons] tinted like a Material [Icon].
class DaymarkIcon extends StatelessWidget {
  const DaymarkIcon(
    this.assetPath, {
    super.key,
    this.color,
    this.size,
    this.width,
    this.height,
    this.semanticLabel,
  });

  final String assetPath;
  final Color? color;
  final double? size;
  final double? width;
  final double? height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 20;
    final tint = color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      assetPath,
      width: width ?? side,
      height: height ?? side,
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
