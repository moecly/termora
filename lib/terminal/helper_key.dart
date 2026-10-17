import 'package:flutter/foundation.dart';
import 'package:xterm2/xterm.dart';

/// Modifier keys that can be latched.
enum TerminalModifier { ctrl, alt, shift }

/// Modifier state for the on-screen helper key bar and hardware keys.
///
/// A modifier latched by a one-shot toggle (on-screen bar) auto-resets after the
/// next consumed key; a modifier held by a hardware key stays down until that
/// key is released, mimicking a physical keyboard.
class KeyModifiers extends ChangeNotifier {
  bool ctrl = false;
  bool alt = false;
  bool shift = false;

  final Set<TerminalModifier> _held = {};

  void toggleCtrl() {
    ctrl = !ctrl;
    notifyListeners();
  }

  void toggleAlt() {
    alt = !alt;
    notifyListeners();
  }

  void toggleShift() {
    shift = !shift;
    notifyListeners();
  }

  /// Sets [key] from a hardware key-down/up event.
  ///
  /// Held modifiers survive [consumeAfterKey] until [held] becomes false.
  void setHeld(TerminalModifier key, bool held) {
    if (held) {
      _held.add(key);
    } else {
      _held.remove(key);
    }
    switch (key) {
      case TerminalModifier.ctrl:
        ctrl = held;
      case TerminalModifier.alt:
        alt = held;
      case TerminalModifier.shift:
        shift = held;
    }
    notifyListeners();
  }

  void clearAll() {
    ctrl = alt = shift = false;
    _held.clear();
    notifyListeners();
  }

  /// Called after a key has been consumed: one-shot Ctrl/Alt latch for one key
  /// only; hardware-held modifiers persist until released.
  void consumeAfterKey() {
    var changed = false;
    if (ctrl && !_held.contains(TerminalModifier.ctrl)) {
      ctrl = false;
      changed = true;
    }
    if (alt && !_held.contains(TerminalModifier.alt)) {
      alt = false;
      changed = true;
    }
    if (changed) notifyListeners();
  }
}

/// Wraps the default terminal input handler so the on-screen modifier state is
/// merged into every key event.
class HelperKeyHandler implements TerminalInputHandler {
  HelperKeyHandler(this._inner, this.modifiers);

  final TerminalInputHandler _inner;
  final KeyModifiers modifiers;

  @override
  String? call(TerminalKeyboardEvent event) {
    if (event.type == TerminalKeyEventType.release) return _inner(event);
    final ctrl = event.ctrl || modifiers.ctrl;
    final alt = event.alt || modifiers.alt;
    final shift = event.shift || modifiers.shift;
    if (!ctrl && !alt && !shift) return _inner(event);
    final result = _inner(event.copyWith(ctrl: ctrl, alt: alt, shift: shift));
    if (result != null) modifiers.consumeAfterKey();
    return result;
  }
}
