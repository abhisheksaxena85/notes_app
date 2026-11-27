import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

/// A `surface` card (design/README.md §3): a 0.5 px soft border and a soft
/// shadow (two layers in light, one deeper one in dark), radius 18 (22 for
/// large cards), padding 16.
///
/// Built for long lists: one [DecoratedBox] with a const [BoxDecoration] per
/// theme and radius, and no clip layer (unless [clipContent]). Taps paint
/// their ink inside the rounded shape through the [InkWell]'s border radius.
class DaymarkCard extends StatelessWidget {
  const DaymarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = defaultRadius,
    this.onTap,
    this.onLongPress,
    this.clipContent = false,
  });

  /// Item, stat and group cards.
  static const double defaultRadius = 18;

  /// Large cards: the calendar month card and the profile card.
  static const double largeRadius = 22;

  /// The space between two stacked cards.
  static const double gap = 10;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Clips the content to the rounded shape. Only for grouped cards whose
  /// rows are tappable edge to edge (their ink would otherwise square off
  /// the corners); item cards in long lists never clip.
  final bool clipContent;

  // The colours are the palette tokens (app_colors.dart), repeated here as
  // compile-time constants so every decoration below is const.
  static const _lightSurface = Color(0xFFFBFBFA);
  static const _lightBorder = Color(0xFFE9E9E5);
  static const _darkSurface = Color(0xFF25262A);
  static const _darkBorder = Color(0xFF33353A);

  /// Light: ink (#2A2B2F) at 5 %, blur 14, y 4, plus ink at 3 %, blur 3, y 1.
  static const lightShadows = [
    BoxShadow(color: Color(0x0D2A2B2F), blurRadius: 14, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x082A2B2F), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Dark: black at 28 %, blur 16, y 6 (the hairline border stays).
  static const darkShadows = [
    BoxShadow(color: Color(0x47000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const _light = BoxDecoration(
    color: _lightSurface,
    borderRadius: BorderRadius.all(Radius.circular(defaultRadius)),
    border: Border.fromBorderSide(BorderSide(color: _lightBorder, width: 0.5)),
    boxShadow: lightShadows,
  );
  static const _lightLarge = BoxDecoration(
    color: _lightSurface,
    borderRadius: BorderRadius.all(Radius.circular(largeRadius)),
    border: Border.fromBorderSide(BorderSide(color: _lightBorder, width: 0.5)),
    boxShadow: lightShadows,
  );
  static const _dark = BoxDecoration(
    color: _darkSurface,
    borderRadius: BorderRadius.all(Radius.circular(defaultRadius)),
    border: Border.fromBorderSide(BorderSide(color: _darkBorder, width: 0.5)),
    boxShadow: darkShadows,
  );
  static const _darkLarge = BoxDecoration(
    color: _darkSurface,
    borderRadius: BorderRadius.all(Radius.circular(largeRadius)),
    border: Border.fromBorderSide(BorderSide(color: _darkBorder, width: 0.5)),
    boxShadow: darkShadows,
  );

  /// The card's decoration for [palette] and [radius].
  static BoxDecoration decorationFor(DaymarkPalette palette, {double radius = defaultRadius}) {
    if (radius == defaultRadius) return palette.isDark ? _dark : _light;
    if (radius == largeRadius) return palette.isDark ? _darkLarge : _lightLarge;
    return (palette.isDark ? _dark : _light)
        .copyWith(borderRadius: BorderRadius.all(Radius.circular(radius)));
  }

  @override
  Widget build(BuildContext context) {
    final decoration = decorationFor(context.daymark, radius: radius);
    final content = Padding(padding: padding, child: child);
    final tappable = onTap != null || onLongPress != null;
    final shape = BorderRadius.all(Radius.circular(radius));
    return DecoratedBox(
      decoration: decoration,
      child: !tappable && !clipContent
          ? content
          : Material(
              type: MaterialType.transparency,
              borderRadius: clipContent ? shape : null,
              clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
              child: tappable
                  ? InkWell(
                      onTap: onTap,
                      onLongPress: onLongPress,
                      borderRadius: shape,
                      child: content,
                    )
                  : content,
            ),
    );
  }
}
