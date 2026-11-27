import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/utils/constants/app_icons.dart';
import 'package:notes_app/utils/themes/daymark_text.dart';

/// The 56 px accent FAB with the add menu (design/README.md §6). Tapping it
/// shows New note / New task / New reminder above it with a 200 ms scale and
/// fade, staggered by 30 ms, and turns the plus into a close icon.
///
/// The open state is owned by the parent through [isOpen] and
/// [onOpenChanged] when given (the Workspace draws the scrim), otherwise
/// internally.
class AddMenuFab extends StatefulWidget {
  const AddMenuFab({
    super.key,
    required this.onNewNote,
    required this.onNewTask,
    required this.onNewReminder,
    this.isOpen,
    this.onOpenChanged,
    this.enabled = true,
  });

  final VoidCallback onNewNote;
  final VoidCallback onNewTask;
  final VoidCallback onNewReminder;
  final bool? isOpen;
  final ValueChanged<bool>? onOpenChanged;

  /// False while the Workspace loads: shown at 45 % opacity, ignores taps.
  final bool enabled;

  @override
  State<AddMenuFab> createState() => _AddMenuFabState();
}

class _AddMenuFabState extends State<AddMenuFab> with SingleTickerProviderStateMixin {
  static const _itemMs = 200;
  static const _staggerMs = 30;
  static const _count = 3;

  bool _internalOpen = false;
  late final AnimationController _controller;
  late final List<CurvedAnimation> _items;

  bool get _isOpen => widget.isOpen ?? _internalOpen;

  @override
  void initState() {
    super.initState();
    const total = _itemMs + _staggerMs * (_count - 1);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: total),
      value: _isOpen ? 1 : 0,
    );
    // Index 0 is the row nearest the FAB; it leads on the way in.
    _items = List.generate(_count, (i) {
      final start = i * _staggerMs / total;
      final end = (i * _staggerMs + _itemMs) / total;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
        reverseCurve: Interval(start, end, curve: Curves.easeInCubic),
      );
    });
  }

  @override
  void didUpdateWidget(AddMenuFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != null && widget.isOpen != oldWidget.isOpen) {
      widget.isOpen! ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _setOpen(bool open) {
    open ? _controller.forward() : _controller.reverse();
    if (widget.onOpenChanged != null) {
      widget.onOpenChanged!(open);
    } else {
      setState(() => _internalOpen = open);
    }
  }

  void _select(VoidCallback action) {
    _setOpen(false);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final rows = [
      ('New reminder', AppIcons.reminder, widget.onNewReminder, 2),
      ('New task', AppIcons.task, widget.onNewTask, 1),
      ('New note', AppIcons.note, widget.onNewNote, 0),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => _controller.isDismissed
              ? const SizedBox.shrink()
              : IgnorePointer(ignoring: !_isOpen, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (label, icon, action, index) in rows) ...[
                _MenuRow(
                  animation: _items[index],
                  label: label,
                  icon: icon,
                  onTap: () => _select(action),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
            ],
          ),
        ),
        Opacity(
          opacity: widget.enabled ? 1 : 0.45,
          child: Semantics(
            button: true,
            enabled: widget.enabled,
            label: _isOpen ? 'Close' : 'Add',
            excludeSemantics: true,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: palette.accent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: widget.enabled ? () => _setOpen(!_isOpen) : null,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => RotationTransition(
                        turns: Tween<double>(begin: 0.75, end: 1).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: DaymarkIcon(
                        _isOpen ? AppIcons.close : AppIcons.plus,
                        key: ValueKey(_isOpen),
                        size: 24,
                        color: palette.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.animation,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final Animation<double> animation;
  final String label;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final shadow = palette.isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : null;
    final border = palette.isDark ? null : Border.all(color: palette.cardBorder);

    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
        alignment: Alignment.centerRight,
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: palette.menuPill,
                      borderRadius: BorderRadius.circular(12),
                      border: border,
                      boxShadow: shadow,
                    ),
                    child: Text(
                      label,
                      style: DaymarkText.custom(14, FontWeight.w500).copyWith(color: palette.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.menuPill,
                      borderRadius: BorderRadius.circular(15),
                      border: border,
                      boxShadow: shadow,
                    ),
                    child: AppIcons.icon(icon, size: 22, color: palette.accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
