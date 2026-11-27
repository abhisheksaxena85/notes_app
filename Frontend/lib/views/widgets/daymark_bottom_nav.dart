import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

class DaymarkNavItem {
  const DaymarkNavItem({required this.icon, required this.label});

  /// An [AppIcons] asset path.
  final String icon;
  final String label;
}

/// The 74 px bottom navigation (design/README.md §6): `surface` with a top
/// hairline. The active item's icon sits in a 60×30 `accentSoft` pill, with
/// icon and label in `accent` at 600; inactive items are `muted`.
class DaymarkBottomNav extends StatelessWidget {
  const DaymarkBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<DaymarkNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    return Container(
      decoration: BoxDecoration(
        color: palette.navSurface,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: DaymarkNavButton(
                    item: items[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DaymarkNavButton extends StatelessWidget {
  const DaymarkNavButton({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
  });

  final DaymarkNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final color = active ? palette.accent : palette.muted;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 60,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? palette.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: AppIcons.icon(item.icon, size: 20, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: DaymarkText.nav(active: active).copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
