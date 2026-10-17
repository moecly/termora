import 'package:flutter/material.dart';

import '../motion.dart';

/// A one-shot staggered entrance: fades in while sliding up slightly.
///
/// The delay is driven by an [Interval] on a single controller (never a
/// `Timer`/`Future.delayed`), so widget tests see no pending timers. When
/// [animate] is false or the system requests reduced motion, the child is
/// returned directly and no controller is created.
class EnterTransition extends StatefulWidget {
  const EnterTransition({
    super.key,
    required this.index,
    this.animate = true,
    this.offsetY = 6,
    required this.child,
  });

  final int index;
  final bool animate;
  final double offsetY;
  final Widget child;

  @override
  State<EnterTransition> createState() => _EnterTransitionState();
}

class _EnterTransitionState extends State<EnterTransition>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  bool _initialized = false;

  Duration get _duration =>
      Motion.panel +
      Motion.stagger * widget.index.clamp(0, Motion.maxStaggerIndex);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (!widget.animate || AppMotion.reduced(context)) return;
    _controller = AnimationController(vsync: this, duration: _duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    final delay = (Motion.stagger * widget.index.clamp(0, Motion.maxStaggerIndex))
            .inMilliseconds /
        _duration.inMilliseconds;
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, 1.0, curve: Motion.emphasized),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
