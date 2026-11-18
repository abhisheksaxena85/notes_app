import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

class AppIcons {
  static const String splashEmblem = 'assets/icons/splash_emblem.svg';
  static const String navNotes = 'assets/icons/nav_notes.svg';
  static const String navCalendar = 'assets/icons/nav_calendar.svg';
  static const String navProfile = 'assets/icons/nav_profile.svg';
  static const String search = 'assets/icons/search.svg';
  static const String pin = 'assets/icons/pin.svg';
  static const String clock = 'assets/icons/clock.svg';
  static const String arrowUpRight = 'assets/icons/arrow_up_right.svg';
  static const String moreDots = 'assets/icons/more_dots.svg';
  static const String moon = 'assets/icons/moon.svg';
  static const String sliders = 'assets/icons/sliders.svg';
  static const String bell = 'assets/icons/bell.svg';
  static const String shield = 'assets/icons/shield.svg';
  static const String cloud = 'assets/icons/cloud.svg';
  static const String help = 'assets/icons/help.svg';
  static const String info = 'assets/icons/info.svg';
  static const String checkCircle = 'assets/icons/check_circle.svg';

  static Widget icon(
    String assetPath, {
    Color? color,
    double? size,
    double? width,
    double? height,
  }) {
    return SvgPicture.asset(
      assetPath,
      width: width ?? size ?? 20,
      height: height ?? size ?? 20,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  /// Exact Figma Splash Logo Emblem Card
  static Widget splashLogo({
    required BuildContext context,
    double size = 84,
  }) {
    final palette = context.daymark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.line, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: palette.brightness == Brightness.dark ? 0.35 : 0.06,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 40 * (size / 84),
          height: 44 * (size / 84),
          child: SvgPicture.string(
            '''<svg viewBox="0 0 40 44" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect width="40" height="44" rx="7" fill="${_toHex(palette.accentSoft)}" stroke="${_toHex(palette.accent)}" stroke-width="1.8"/>
              <line x1="9" y1="0" x2="9" y2="44" stroke="${_toHex(palette.accent)}" stroke-width="1.5"/>
              <path d="M22 0V16L26.5 12.5L31 16V0" fill="${_toHex(palette.accent)}"/>
              <line x1="14" y1="24" x2="33" y2="24" stroke="${_toHex(palette.accent)}" stroke-width="1.5" stroke-linecap="round"/>
              <line x1="14" y1="32" x2="28" y2="32" stroke="${_toHex(palette.accent)}" stroke-width="1.5" stroke-linecap="round"/>
            </svg>''',
          ),
        ),
      ),
    );
  }

  static String _toHex(Color color) {
    final hexString = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hexString.substring(2)}';
  }
}
