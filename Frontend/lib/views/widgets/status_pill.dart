import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// The "Missed" / "Rejected" pill: `dangerSoft` fill, `danger` text 12/600,
/// radius 8.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key});

  final String label;

  /// "MISSED" → "Missed".
  static String labelFor(String status) =>
      status.isEmpty ? status : status[0].toUpperCase() + status.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.dangerSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: DaymarkText.custom(12, FontWeight.w600).copyWith(color: palette.danger),
      ),
    );
  }
}

/// A small muted icon button with a 44 px touch target (card delete).
class CardIconButton extends StatelessWidget {
  const CardIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: icon,
      color: color ?? context.daymark.muted,
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }
}
