import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:xterm2/xterm.dart';

import '../data/key_mapping.dart';
import '../data/settings_repository.dart';
import '../terminal/helper_key.dart';
import 'session_manager.dart';
import 'terminal_session.dart';

/// Platform channel used by `MainActivity` to forward intercepted hardware keys.
const MethodChannel _channel = MethodChannel('termora/hardware_keys');

/// Bridges Android hardware keys (volume/camera) to terminal actions.
///
/// On non-Android platforms [init] is a no-op. The set of intercepted key codes
/// is pushed to the native side whenever the mappings change; key-down events
/// are delivered back over the same channel and applied to the active session.
class HardwareKeyService {
  HardwareKeyService({required this.manager, required this.settings});

  final SessionManager manager;
  final SettingsRepository settings;

  Future<void> init() async {
    if (!Platform.isAndroid) return;
    settings.addListener(_sync);
    _channel.setMethodCallHandler(_onCall);
    await _pushInterceptedKeys();
  }

  void dispose() => settings.removeListener(_sync);

  void _sync() {
    unawaited(_pushInterceptedKeys());
  }

  Future<void> _pushInterceptedKeys() async {
    final codes = <int>[];
    for (final m in settings.settings.keyMappings) {
      for (final s in kKeyMappingSources) {
        if (s.id == m.source) codes.add(s.androidKeyCode);
      }
    }
    try {
      await _channel.invokeMethod<void>('setInterceptedKeys', {'keyCodes': codes});
    } on Object {
      // Native side unavailable (e.g. non-Android host): ignore.
    }
  }

  Future<void> _onCall(MethodCall call) async {
    if (call.method != 'keyEvent') return;
    final args = (call.arguments as Map).cast<String, Object?>();
    final keyCode = args['keyCode'];
    if (keyCode is! int) return;
    final isDown = args['action'] == 'down';
    final repeat = (args['repeatCount'] as num?)?.toInt() ?? 0;
    if (isDown && repeat > 0) return; // ignore auto-repeat, like a held key
    _apply(keyCode, down: isDown);
  }

  TerminalModifier? _modifierFor(String action) => switch (action) {
        'ctrl' => TerminalModifier.ctrl,
        'alt' => TerminalModifier.alt,
        'shift' => TerminalModifier.shift,
        _ => null,
      };

  void _apply(int keyCode, {required bool down}) {
    final session = manager.active;
    if (session == null) return;
    for (final m in settings.settings.keyMappings) {
      KeyMappingSource? src;
      for (final s in kKeyMappingSources) {
        if (s.id == m.source) {
          src = s;
          break;
        }
      }
      if (src == null || src.androidKeyCode != keyCode) continue;

      final modifier = _modifierFor(m.action);
      if (modifier != null) {
        // Momentary, like a real keyboard: down latches, up releases.
        session.modifiers.setHeld(modifier, down);
      } else if (down) {
        _emitKey(session, m.action);
      }
    }
  }

  void _emitKey(TerminalSession session, String action) {
    final key = switch (action) {
      'escape' => TerminalKey.escape,
      'tab' => TerminalKey.tab,
      'enter' => TerminalKey.enter,
      'backspace' => TerminalKey.backspace,
      'arrowUp' => TerminalKey.arrowUp,
      'arrowDown' => TerminalKey.arrowDown,
      'arrowLeft' => TerminalKey.arrowLeft,
      'arrowRight' => TerminalKey.arrowRight,
      'pageUp' => TerminalKey.pageUp,
      'pageDown' => TerminalKey.pageDown,
      'home' => TerminalKey.home,
      'end' => TerminalKey.end,
      'delete' => TerminalKey.delete,
      _ => null,
    };
    if (key != null) session.terminal.keyInput(key);
  }
}
