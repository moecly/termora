import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import '../data/settings_repository.dart';
import '../design/tokens.dart';
import '../session/session_status.dart';

/// Memoized terminal text style, keyed by font size, so that rebuilding the
/// viewport does not hand a fresh [TerminalStyle] to `TerminalView` on every
/// build (which would reset the color scheme).
final Map<double, TerminalStyle> _cache = {};

TerminalStyle terminalStyleFor(double fontSize) {
  return _cache.putIfAbsent(
    fontSize,
    () => TerminalStyle(
      fontSize: fontSize,
      height: 1.25,
      fontFamily: 'monospace',
    ),
  );
}

/// Status colour for the terminal app bar, tuned for contrast against the
/// terminal palette background (which may be light or dark).
Color terminalStatusColor(SessionStatus status, TerminalTheme theme) {
  final lightBackground = theme.background.computeLuminance() > 0.5;
  return switch (status) {
    SessionStatus.connecting =>
      lightBackground ? const Color(0xFF9A6700) : AppColors.warning,
    SessionStatus.connected =>
      lightBackground ? const Color(0xFF1F7A4D) : AppColors.success,
    SessionStatus.disconnected => theme.foreground.withValues(alpha: 0.75),
    SessionStatus.failed =>
      lightBackground ? const Color(0xFFC4322F) : AppColors.danger,
  };
}

/// New font size after a pinch gesture.
///
/// [base] is the font size when the pinch started; the result is stepped to
/// 0.5pt (to avoid unbounded terminal-style cache growth) and clamped to
/// [kTerminalFontSizeMin]..[kTerminalFontSizeMax].
double pinchFontSize({
  required double base,
  required double startDistance,
  required double currentDistance,
}) {
  if (startDistance <= 0 || currentDistance <= 0) return base;
  final raw = base * currentDistance / startDistance;
  final stepped = (raw * 2).round() / 2;
  return stepped.clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
}
