import 'package:flutter/material.dart';

import '../motion.dart';

/// Reveals [child] by clipping it along [axis] toward [alignment]. When [open]
/// flips the widget animates between collapsed and revealed; the first build
/// settles instantly at the target (no [Tween.begin]).
class MaskReveal extends StatelessWidget {
  const MaskReveal({
    super.key,
    required this.open,
    required this.child,
    this.axis = Axis.horizontal,
    this.alignment,
    this.duration = Motion.panel,
    this.curve = Motion.emphasized,
  });

  final bool open;
  final Widget child;
  final Axis axis;
  final Alignment? alignment;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final horizontal = axis == Axis.horizontal;
    final resolvedAlignment =
        alignment ?? (horizontal ? Alignment.centerLeft : Alignment.topCenter);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: open ? 1.0 : 0.0),
      duration: AppMotion.scale(context, duration),
      curve: curve,
      child: child,
      builder: (context, t, child) => ClipRect(
        child: Align(
          alignment: resolvedAlignment,
          widthFactor: horizontal ? t : null,
          heightFactor: horizontal ? null : t,
          child: child,
        ),
      ),
    );
  }
}
