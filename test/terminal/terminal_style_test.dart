import 'package:flutter_test/flutter_test.dart';
import 'package:termora/session/session_status.dart';
import 'package:termora/terminal/terminal_style.dart';
import 'package:termora/terminal/terminal_themes.dart';

void main() {
  group('pinchFontSize', () {
    test('scales linearly with the distance ratio', () {
      expect(
        pinchFontSize(base: 13, startDistance: 100, currentDistance: 200),
        26.0,
      );
    });

    test('clamps to the lower bound', () {
      expect(
        pinchFontSize(base: 13, startDistance: 100, currentDistance: 1),
        8.0,
      );
    });

    test('clamps to the upper bound', () {
      expect(
        pinchFontSize(base: 13, startDistance: 100, currentDistance: 1000),
        28.0,
      );
    });

    test('returns base for degenerate distances', () {
      expect(pinchFontSize(base: 13, startDistance: 0, currentDistance: 50), 13);
      expect(pinchFontSize(base: 13, startDistance: 100, currentDistance: 0), 13);
    });
  });

  test('status colour depends on the terminal background', () {
    expect(
      terminalStatusColor(SessionStatus.connected, termoraDark),
      isNot(terminalStatusColor(SessionStatus.connected, solarizedLight)),
    );
  });
}
