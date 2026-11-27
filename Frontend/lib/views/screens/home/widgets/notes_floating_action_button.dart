import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

class AddSpeedDialFab extends StatefulWidget {
  final VoidCallback onNewNote;
  final VoidCallback onNewTask;
  final VoidCallback onNewReminder;
  final bool? isOpen;
  final ValueChanged<bool>? onOpenChanged;

  const AddSpeedDialFab({
    super.key,
    required this.onNewNote,
    required this.onNewTask,
    required this.onNewReminder,
    this.isOpen,
    this.onOpenChanged,
  });

  @override
  State<AddSpeedDialFab> createState() => _AddSpeedDialFabState();
}

class _AddSpeedDialFabState extends State<AddSpeedDialFab>
    with SingleTickerProviderStateMixin {
  bool _internalOpen = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  late List<CurvedAnimation> _itemAnimations;

  bool get _isOpen => widget.isOpen ?? _internalOpen;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: math.pi / 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Staggered entrance: the pill nearest the FAB (index 0 = Note) leads.
    _itemAnimations = List.generate(3, (index) {
      final start = index * 0.15;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, 1.0, curve: Curves.easeOutBack),
        reverseCurve: Interval(0.0, 1.0 - start, curve: Curves.easeIn),
      );
    });

    if (_isOpen) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AddSpeedDialFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != null && widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen!) {
        if (_controller.status != AnimationStatus.forward &&
            _controller.status != AnimationStatus.completed) {
          _controller.forward();
        }
      } else {
        if (_controller.status != AnimationStatus.reverse &&
            _controller.status != AnimationStatus.dismissed) {
          _controller.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    for (final animation in _itemAnimations) {
      animation.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = !_isOpen;
    if (next) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    if (widget.onOpenChanged != null) {
      widget.onOpenChanged!(next);
    } else {
      setState(() {
        _internalOpen = next;
      });
    }
  }

  void _close() {
    if (_isOpen) {
      _toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final isDark = palette.brightness == Brightness.dark;
    final fabBg = isDark ? palette.accent : palette.ink;
    final fabFg = isDark ? palette.background : palette.surface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Smoothly expand/collapse options without taking layout space when closed
        SizeTransition(
          sizeFactor: _expandAnimation,
          alignment: Alignment.bottomRight,
          child: IgnorePointer(
            ignoring: !_isOpen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Option 3: New Reminder (Purple)
                _buildSpeedDialItem(
                  label: "New Reminder",
                  index: 2,
                  icon: Icons.notifications_active_outlined,
                  iconColor: palette.accent,
                  iconBg: palette.accent.withValues(alpha: 0.15),
                  onTap: () {
                    _close();
                    widget.onNewReminder();
                  },
                  palette: palette,
                ),
                SizedBox(height: 10.h),

                // Option 2: New Task (Blue)
                _buildSpeedDialItem(
                  label: "New Task",
                  index: 1,
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: palette.accent,
                  iconBg: palette.accent.withValues(alpha: 0.15),
                  onTap: () {
                    _close();
                    widget.onNewTask();
                  },
                  palette: palette,
                ),
                SizedBox(height: 10.h),

                // Option 1: New Note (Accent)
                _buildSpeedDialItem(
                  label: "New Note",
                  index: 0,
                  icon: Icons.edit_note_rounded,
                  iconColor: palette.accent,
                  iconBg: palette.accentSoft,
                  onTap: () {
                    _close();
                    widget.onNewNote();
                  },
                  palette: palette,
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),

        // Main Trigger Button ("+ Add")
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: fabBg,
            borderRadius: BorderRadius.circular(18.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(18.r),
              onTap: _toggle,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _rotateAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: Icon(
                            Icons.add_rounded,
                            color: fabFg,
                            size: 22.sp,
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _isOpen ? 'Close' : 'Add',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: fabFg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem({
    required String label,
    required int index,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
    required DaymarkPalette palette,
  }) {
    return ScaleTransition(
      scale: _itemAnimations[index],
      alignment: Alignment.bottomRight,
      child: FadeTransition(
        opacity: _itemAnimations[index],
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: EdgeInsets.only(right: 2.w),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: palette.line, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18.sp,
                    color: iconColor,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Backward-compatible fallback helper
Widget notesFloatingActionButton({
  required BuildContext context,
  VoidCallback? onPressed,
}) {
  return AddSpeedDialFab(
    onNewNote: onPressed ?? () {},
    onNewTask: () {},
    onNewReminder: () {},
  );
}
