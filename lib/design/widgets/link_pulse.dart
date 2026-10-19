import 'package:flutter/material.dart';

import '../motion.dart';
import '../palette.dart';

/// A thin scanning line used to signal "activity in progress": a light band
/// sweeps along the [axis]. When [active] is false it draws a static hairline.
class LinkPulse extends StatefulWidget {
  const LinkPulse({
    super.key,
    required this.active,
    this.color,
    this.height = 2,
    this.axis = Axis.horizontal,
    this.period = Motion.pulse,
    this.intensity = 1.0,
  });

  final bool active;
  final Color? color;
  final double height;
  final Axis axis;
  final Duration period;
  final double intensity;

  @override
  State<LinkPulse> createState() => _LinkPulseState();
}

class _LinkPulseState extends State<LinkPulse>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LinkPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final want = widget.active && !AppMotion.reduced(context);
    if (!want) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    if (_controller == null) {
      _controller = AnimationController(vsync: this, duration: widget.period)
        ..repeat();
    } else if (_controller!.duration != widget.period) {
      _controller!
        ..duration = widget.period
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = widget.color ?? p.signal;
    final controller = _controller;
    if (controller == null) {
      return RepaintBoundary(
        child: Container(
          height: widget.height,
          color: widget.active ? color.withValues(alpha: 0.35) : p.border,
        ),
      );
    }
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final t = controller.value;
            final begin = -1.4 + 2.4 * t;
            final end = -0.4 + 2.4 * t;
            final vertical = widget.axis == Axis.vertical;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: vertical ? Alignment(0, begin) : Alignment(begin, 0),
                  end: vertical ? Alignment(0, end) : Alignment(end, 0),
                  colors: [
                    Colors.transparent,
                    color.withValues(alpha: 0.85 * widget.intensity),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
