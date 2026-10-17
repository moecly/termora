import 'package:flutter_test/flutter_test.dart';
import 'package:xterm2/xterm.dart';

import 'package:termora/terminal/helper_key.dart';

TerminalKeyboardEvent _event(TerminalKey key, {String? text}) {
  return TerminalKeyboardEvent(
    key: key,
    shift: false,
    ctrl: false,
    alt: false,
    state: Terminal(),
    altBuffer: false,
    platform: TerminalTargetPlatform.linux,
    text: text,
  );
}

class _RecordingHandler implements TerminalInputHandler {
  _RecordingHandler(this.result);
  final String? result;
  final List<TerminalKeyboardEvent> events = [];

  @override
  String? call(TerminalKeyboardEvent event) {
    events.add(event);
    return result;
  }
}

void main() {
  late KeyModifiers modifiers;
  late HelperKeyHandler handler;

  setUp(() {
    modifiers = KeyModifiers();
    handler = HelperKeyHandler(defaultInputHandler, modifiers);
  });

  tearDown(() => modifiers.dispose());

  test('ctrl modifier turns keyC into Ctrl-C (0x03)', () {
    modifiers.toggleCtrl();
    expect(handler(_event(TerminalKey.keyC)), '\x03');
  });

  test('ctrl + text input "c" also yields 0x03', () {
    modifiers.toggleCtrl();
    expect(handler(_event(TerminalKey.keyC, text: 'c')), '\x03');
  });

  test('alt modifier prefixes the key with ESC', () {
    modifiers.toggleAlt();
    expect(handler(_event(TerminalKey.keyB)), '\x1bb');
  });

  test('shift modifier is merged into the event before delegating', () {
    final inner = _RecordingHandler('A');
    final merging = HelperKeyHandler(inner, modifiers);
    modifiers.toggleShift();

    expect(merging(_event(TerminalKey.keyA)), 'A');
    expect(inner.events.single.shift, isTrue);
    expect(inner.events.single.ctrl, isFalse);
  });

  test('ctrl/alt reset after a consumed key, shift stays', () {
    modifiers.toggleCtrl();
    modifiers.toggleAlt();
    modifiers.toggleShift();
    handler(_event(TerminalKey.keyC));
    expect(modifiers.ctrl, isFalse);
    expect(modifiers.alt, isFalse);
    expect(modifiers.shift, isTrue);
  });

  test('without modifiers the inner handler result is returned unchanged', () {
    final direct = defaultInputHandler(_event(TerminalKey.keyA));
    expect(handler(_event(TerminalKey.keyA)), direct);
  });

  test('release events bypass modifier merging', () {
    modifiers.toggleCtrl();
    final event = TerminalKeyboardEvent(
      key: TerminalKey.keyC,
      shift: false,
      ctrl: false,
      alt: false,
      state: Terminal(),
      altBuffer: false,
      platform: TerminalTargetPlatform.linux,
      type: TerminalKeyEventType.release,
    );
    handler(event);
    expect(modifiers.ctrl, isTrue);
  });

  test('clearAll resets every modifier', () {
    modifiers.toggleCtrl();
    modifiers.toggleAlt();
    modifiers.toggleShift();
    modifiers.clearAll();
    expect(modifiers.ctrl, isFalse);
    expect(modifiers.alt, isFalse);
    expect(modifiers.shift, isFalse);
  });

  test('hardware hold sets the modifier on and release clears it', () {
    modifiers.setHeld(TerminalModifier.ctrl, true);
    expect(modifiers.ctrl, isTrue);
    modifiers.setHeld(TerminalModifier.ctrl, false);
    expect(modifiers.ctrl, isFalse);
  });

  test('a hardware-held modifier survives a consumed key', () {
    modifiers.setHeld(TerminalModifier.ctrl, true);
    handler(_event(TerminalKey.keyC));
    // Not reset: the key is still physically held.
    expect(modifiers.ctrl, isTrue);
    // Releasing it clears the state.
    modifiers.setHeld(TerminalModifier.ctrl, false);
    expect(modifiers.ctrl, isFalse);
  });
}
