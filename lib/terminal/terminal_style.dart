import 'package:xterm2/xterm.dart';

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
