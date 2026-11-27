import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';

/// The loading shimmer (design/README.md §7). Wrap a whole skeleton screen in
/// one [Shimmer]: it owns the single animation controller, and every
/// [SkeletonBox] below it paints the same screen-wide gradient
/// (`skeletonBase → skeletonHighlight → skeletonBase`, stops 0.25 / 0.37 /
/// 0.63) sweeping left to right every 1.4 s, so all blocks sweep together.
///
/// When [MediaQuery.disableAnimationsOf] is true the blocks are static
/// `skeletonBase`. The subtree is announced as "Loading…".
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.semanticLabel = 'Loading…',
  });

  final Widget child;
  final String semanticLabel;

  static const period = Duration(milliseconds: 1400);

  /// The nearest [Shimmer] above [context], or null.
  static ShimmerState? of(BuildContext context) =>
      context.findAncestorStateOfType<ShimmerState>();

  @override
  State<Shimmer> createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Shimmer.period,
  );
  bool _static = false;

  /// Ticks while the shimmer sweeps.
  Listenable get animation => _controller;

  /// True when animations are disabled: blocks paint plain `skeletonBase`.
  bool get isStatic => _static;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _static = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_static) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The gradient at the current point of the sweep.
  LinearGradient gradient(DaymarkPalette palette) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [palette.skeletonBase, palette.skeletonHighlight, palette.skeletonBase],
        stops: const [0.25, 0.37, 0.63],
        transform: _SweepTransform(Curves.ease.transform(_controller.value)),
      );

  /// The rectangle the gradient spans in [descendant]'s coordinates: the
  /// whole shimmer area, so neighbouring blocks line up.
  Rect? shaderRectFor(RenderBox descendant) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !descendant.attached || !descendant.hasSize) {
      return null;
    }
    final offset = descendant.localToGlobal(Offset.zero, ancestor: box);
    return Rect.fromLTWH(-offset.dx, -offset.dy, box.size.width, box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      container: true,
      child: widget.child,
    );
  }
}

/// Slides the gradient from fully left (t = 0) to fully right (t = 1).
class _SweepTransform extends GradientTransform {
  const _SweepTransform(this.t);

  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (2 * t - 1), 0, 0);
}
