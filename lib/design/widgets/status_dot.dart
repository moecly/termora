import 'package:flutter/material.dart';

import '../../session/session_status.dart';
import '../tokens.dart';

/// A small colored dot reflecting a session's status. The `connecting` state
/// gently pulses its opacity.
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
  void initState() {
    super.initState();
    if (_pulses) _startController();
  }

  @override
  void didUpdateWidget(StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pulses && _controller == null) {
      _startController();
    } else if (!_pulses && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  void _startController() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
    final dot = Container(
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
