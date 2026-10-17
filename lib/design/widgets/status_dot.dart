import 'package:flutter/material.dart';

import '../../session/session_status.dart';
import '../motion.dart';
import '../tokens.dart';

/// A small colored dot reflecting a session's status. The `connecting` state
/// gently pulses its opacity (skipped under reduced motion).
class StatusDot extends StatefulWidget {
  const StatusDot({super.key, required this.status, this.size = 8});

  final SessionStatus status;
  final double size;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _pulses => widget.status == SessionStatus.connecting;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final shouldPulse = _pulses && !AppMotion.reduced(context);
    if (shouldPulse && _controller == null) {
      _controller = AnimationController(vsync: this, duration: Motion.pulse)
        ..repeat(reverse: true);
    } else if (!shouldPulse && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Color _color(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (widget.status) {
      SessionStatus.connecting => AppColors.warning,
      SessionStatus.connected => AppColors.success,
      SessionStatus.disconnected =>
        dark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
      SessionStatus.failed => AppColors.danger,
    };
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final dot = AnimatedContainer(
      duration: reduced ? Duration.zero : Motion.control,
      curve: Motion.easeInOut,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: _color(context), shape: BoxShape.circle),
    );
    final controller = _controller;
    if (controller == null) return dot;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Opacity(
        opacity: 0.4 + 0.6 * controller.value,
        child: child,
      ),
      child: dot,
    );
  }
}
