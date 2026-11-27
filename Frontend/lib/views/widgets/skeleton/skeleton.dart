import 'package:flutter/material.dart';
import 'package:notes_app/utils/constants/app_colors.dart';
import 'package:notes_app/views/widgets/skeleton/shimmer.dart';

export 'shimmer.dart';

/// A skeleton block with its real size and radius. Shimmers with the
/// nearest [Shimmer]; static `skeletonBase` without one or when animations
/// are disabled.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.daymark;
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.skeletonBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    final shimmer = Shimmer.of(context);
    if (shimmer == null || shimmer.isStatic) return box;
    return AnimatedBuilder(
      animation: shimmer.animation,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final self = context.findRenderObject();
          final rect = self is RenderBox ? shimmer.shaderRectFor(self) : null;
          return shimmer.gradient(palette).createShader(rect ?? bounds);
        },
        child: child,
      ),
      child: box,
    );
  }
}

/// A text bar: [height] 10–14 with a radius of half its height, as wide as
/// [widthFactor] of the available width (vary it, 0.35–0.75).
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.widthFactor = 0.6, this.height = 12});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: SkeletonBox(height: height, radius: height / 2),
    );
  }
}

/// A circle (avatar, checkbox) at its real [size].
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      SkeletonBox(width: size, height: size, radius: size / 2);
}
