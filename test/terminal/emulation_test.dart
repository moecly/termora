import 'package:flutter_test/flutter_test.dart';
import 'package:xterm2/xterm.dart';

Terminal _terminal() {
  final terminal = Terminal(maxLines: 1000);
  terminal.resize(80, 24);
  return terminal;
}

void main() {
  test('plain text is written into the buffer', () {
    final terminal = _terminal();
    terminal.write('hello\r\n');
    expect(
      terminal.buffer.getText(null, true),
      contains('hello'),
    );
  });

  test('alternate screen buffer is entered and left', () {
    final terminal = _terminal();
    expect(terminal.isUsingAltBuffer, isFalse);
    terminal.write('\x1b[?1049h');
    expect(terminal.isUsingAltBuffer, isTrue);
    terminal.write('\x1b[?1049l');
    expect(terminal.isUsingAltBuffer, isFalse);
  });

  test('clear + home leaves only the new content on screen', () {
    final terminal = _terminal();
    terminal.write('first screen');
    terminal.write('\x1b[2J\x1b[H');
    terminal.write('world');
    final text = terminal.buffer.getText(null, true);
    expect(text, contains('world'));
    expect(text, isNot(contains('first screen')));
  });

  test('SGR color sequences advance the cursor without printing glyphs', () {
    final terminal = _terminal();
    expect(terminal.buffer.cursorX, 0);
    terminal.write('\x1b[31mred');
    expect(terminal.buffer.cursorX, 3);
    expect(terminal.buffer.getText(null, true), contains('red'));
  });

  test('carriage return returns the cursor to column 0', () {
    final terminal = _terminal();
    terminal.write('abcdef\r');
    expect(terminal.buffer.cursorX, 0);
  });

  test('newline advances the cursor row', () {
    final terminal = _terminal();
    terminal.write('a\r\nb');
    expect(terminal.buffer.cursorY, 1);
    expect(terminal.buffer.cursorX, 1);
  });
}
