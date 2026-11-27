import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Daymark type scale (design/README.md §2), all Inter. Styles carry no
/// colour; add one with `copyWith(color: …)`.
class DaymarkText {
  const DaymarkText._();

  static TextStyle _inter(
    double size,
    FontWeight weight, {
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// 26 / 600 / -0.5: note title in the editor.
  static TextStyle get display => _inter(26, FontWeight.w600, letterSpacing: -0.5);

  /// 24 / 600 / -0.4: screen titles, greeting.
  static TextStyle get title => _inter(24, FontWeight.w600, letterSpacing: -0.4);

  /// 19 / 600 / -0.3: bottom-sheet titles.
  static TextStyle get sheetTitle => _inter(19, FontWeight.w600, letterSpacing: -0.3);

  /// 15 / 600: section headers.
  static TextStyle get section => _inter(15, FontWeight.w600);

  /// 15 / 500: card titles.
  static TextStyle get bodyStrong => _inter(15, FontWeight.w500);

  /// 15.5 / 400 / 1.6: note body.
  static TextStyle get body => _inter(15.5, FontWeight.w400, height: 1.6);

  /// 13.5 / 400 / 1.45: note preview.
  static TextStyle get preview => _inter(13.5, FontWeight.w400, height: 1.45);

  /// 12.5 / 400: times, categories, captions.
  static TextStyle get meta => _inter(12.5, FontWeight.w400);

  /// 12.5 / 500: form field labels.
  static TextStyle get label => _inter(12.5, FontWeight.w500);

  /// 12 / 600 / +0.3: group labels. Uppercase the text yourself.
  static TextStyle get overline => _inter(12, FontWeight.w600, letterSpacing: 0.3);

  /// 13 / 500 (600 selected): chips, segmented controls.
  static TextStyle chip({bool selected = false}) =>
      _inter(13, selected ? FontWeight.w600 : FontWeight.w500);

  /// 15 / 600: primary buttons.
  static TextStyle get button => _inter(15, FontWeight.w600);

  /// 11.5 / 500 (600 active): bottom-nav labels.
  static TextStyle nav({bool active = false}) =>
      _inter(11.5, active ? FontWeight.w600 : FontWeight.w500);

  /// Any other size in Inter, for one-off values the spec gives in px.
  static TextStyle custom(double size, FontWeight weight, {double? height, double? letterSpacing}) =>
      _inter(size, weight, height: height, letterSpacing: letterSpacing);
}
