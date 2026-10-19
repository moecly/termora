import 'package:flutter/material.dart';

import '../../design/motion.dart';
import '../../design/palette.dart';
import '../../design/tokens.dart';
import '../../design/widgets/link_pulse.dart';
import '../../design/widgets/server_avatar.dart';
import '../../session/session_status.dart';
import '../../session/terminal_session.dart';

/// A connection-in-progress overlay for a session: avatar, endpoint, a scanning
/// pulse and a live status line. Only meaningful while connecting.
class ConnectSequence extends StatefulWidget {
  const ConnectSequence({super.key, required this.session});

  final TerminalSession session;

  @override
  State<ConnectSequence> createState() => _ConnectSequenceState();
}

class _ConnectSequenceState extends State<ConnectSequence>
    with SingleTickerProviderStateMixin {
  AnimationController? _scan;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scan == null && !AppMotion.reduced(context)) {
      _scan = AnimationController(vsync: this, duration: Motion.pulse)..repeat();
    }
  }

  @override
  void dispose() {
    _scan?.dispose();
    super.dispose();
  }

  String get _statusText {
    switch (widget.session.status) {
      case SessionStatus.connecting:
        return '正在建立连接…';
      case SessionStatus.connected:
        return '已连接';
      case SessionStatus.failed:
        return widget.session.errorMessage ?? '连接失败';
      case SessionStatus.disconnected:
        return widget.session.errorMessage ?? '连接已断开';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final s = widget.session.server;
    final scan = _scan;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _DotFieldPainter(color: p.textTertiary)),
          if (scan != null)
            AnimatedBuilder(
              animation: scan,
              builder: (context, _) => CustomPaint(
                painter: _ScanPainter(color: p.accent, t: scan.value),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ServerAvatar(
                  seed: s.name,
                  size: 56,
                  status: widget.session.status,
                ),
                const SizedBox(height: Space.x4),
                Text(s.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: Space.x1),
                Text(
                  '${s.username}@${s.host}:${s.port}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ).copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: Space.x4),
                SizedBox(
                  width: 220,
                  child: LinkPulse(
                    active: widget.session.status == SessionStatus.connecting,
                    color: p.signal,
                  ),
                ),
                const SizedBox(height: Space.x3),
                Text(
                  _statusText,
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotFieldPainter extends CustomPainter {
  _DotFieldPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.18);
    const step = 24.0;
    for (var x = step; x < size.width; x += step) {
      for (var y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotFieldPainter old) => old.color != color;
}

class _ScanPainter extends CustomPainter {
  _ScanPainter({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * t;
    final rect = Rect.fromLTWH(0, y - 40, size.width, 80);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            color.withValues(alpha: 0.30),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t || old.color != color;
}
