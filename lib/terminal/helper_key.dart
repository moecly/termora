import 'package:flutter/foundation.dart';
import 'package:xterm2/xterm.dart';

/// Modifier state for the on-screen helper key bar.
///
/// Ctrl/Alt auto-reset after the next consumed key; Shift is sticky so the user
/// can type several capitals/symbols in a row.
class KeyModifiers extends ChangeNotifier {
  bool ctrl = false;
  bool alt = false;
  bool shift = false;

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

  void clearAll() {
    ctrl = alt = shift = false;
    notifyListeners();
  }

  /// Called after a key has been consumed: Ctrl/Alt latch for one key only.
  void consumeAfterKey() {
    if (ctrl || alt) {
      ctrl = false;
      alt = false;
      notifyListeners();
    }
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
