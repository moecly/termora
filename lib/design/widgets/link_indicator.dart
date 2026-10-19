import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../session/session_status.dart';
import '../motion.dart';
import '../palette.dart';

/// How prominent a [LinkIndicator] is.
enum LinkEmphasis {
  /// Sits inline next to text — just the glyph.
  inline,

  /// Stands alone — adds an outward pulse ring behind the glyph.
  standalone,
}

/// Status → color mapping shared by [LinkIndicator] and [ServerAvatar].
Color linkStatusColor(AppPalette p, SessionStatus status) => switch (status) {
  SessionStatus.connecting => p.warn,
  SessionStatus.connected => p.live,
  SessionStatus.disconnected => p.idle,
  SessionStatus.failed => p.danger,
};

/// A small status glyph that morphs between session states: a sweeping arc
/// while connecting, a filled dot when connected, a hollow ring when
/// disconnected and a slashed dot on failure.
class LinkIndicator extends StatefulWidget {
  const LinkIndicator({
    super.key,
    required this.status,
    this.size = 9,
    this.emphasis = LinkEmphasis.inline,
  });

  final SessionStatus status;
  final double size;
  final LinkEmphasis emphasis;

  @override
  State<LinkIndicator> createState() => _LinkIndicatorState();
}

class _LinkIndicatorState extends State<LinkIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _connects => widget.status == SessionStatus.connecting;
  bool get _pulses =>
      widget.emphasis == LinkEmphasis.standalone &&
      (widget.status == SessionStatus.connecting ||
          widget.status == SessionStatus.connected);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LinkIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final wantController = !AppMotion.reduced(context) && (_connects || _pulses);
    if (!wantController) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    final period = _connects ? Motion.pulse : Motion.breathe;
    if (_controller == null) {
      _controller = AnimationController(vsync: this, duration: period)..repeat();
    } else if (_controller!.duration != period) {
      _controller!
        ..duration = period
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
    final color = linkStatusColor(p, widget.status);
    final standalone = widget.emphasis == LinkEmphasis.standalone;
    final canvas = widget.size + (standalone ? 10 : 0);

    Widget painter(double t) => RepaintBoundary(
      child: CustomPaint(
        size: Size.square(canvas),
        painter: _LinkPainter(
          status: widget.status,
          color: color,
          surface: p.surface,
          size: widget.size,
          standalone: standalone,
          progress: t,
          reduced: AppMotion.reduced(context),
        ),
      ),
    );

    final controller = _controller;
    final glyph = controller == null
        ? painter(0)
        : AnimatedBuilder(
            animation: controller,
            builder: (context, _) => painter(controller.value),
          );

    return AnimatedSwitcher(
      duration: AppMotion.scale(context, Motion.control),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(widget.status), child: glyph),
    );
  }
}

class _LinkPainter extends CustomPainter {
  _LinkPainter({
    required this.status,
    required this.color,
    required this.surface,
    required this.size,
    required this.standalone,
    required this.progress,
    required this.reduced,
  });

  final SessionStatus status;
  final Color color;
  final Color surface;
  final double size;
  final bool standalone;
  final double progress;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

    if (standalone) {
      final t = progress;
      final scale = 1 + 0.9 * t;
      final alpha = 0.35 * (1 - t);
      canvas.drawCircle(
        center,
        (size / 2) * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }

    final fill = Paint()..color = color;
    switch (status) {
      case SessionStatus.connecting:
        final angle = reduced ? math.pi / 4 : progress * 2 * math.pi;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: (size - 2) / 2),
          angle,
          0.35 * math.pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
        canvas.drawCircle(center, size * 0.22, fill);
      case SessionStatus.connected:
        canvas.drawCircle(center, size / 2, fill);
      case SessionStatus.disconnected:
        canvas.drawCircle(
          center,
          (size - 1.5) / 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = color,
        );
      case SessionStatus.failed:
        canvas.drawCircle(center, size / 2, fill);
        final d = size * 0.32;
        canvas.drawLine(
          center + Offset(-d, -d),
          center + Offset(d, d),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..color = surface,
        );
    }
  }

  @override
  bool shouldRepaint(_LinkPainter old) =>
      old.status != status ||
      old.color != color ||
      old.surface != surface ||
      old.size != size ||
      old.standalone != standalone ||
      old.progress != progress ||
      old.reduced != reduced;
}
