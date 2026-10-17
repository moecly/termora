import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import '../../design/tokens.dart';
import '../../session/terminal_session.dart';

/// The on-screen helper key bar (Esc, Ctrl, arrows, symbols, clipboard, ...).
class HelperKeyBar extends StatelessWidget {
  const HelperKeyBar({super.key, required this.session});

  final TerminalSession session;

  void _key(TerminalKey key) => session.terminal.keyInput(key);

  void _text(String text) => session.terminal.textInput(text);

  void _invoke(Intent intent) {
    final context = session.builderKey.currentContext;
    if (context == null) return;
    Actions.invoke(context, intent);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListenableBuilder(
        listenable: Listenable.merge([session.modifiers, session.terminalController]),
        builder: (context, _) {
          final hasSelection = session.terminalController.selection != null;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.x2),
            child: Row(
              children: [
                _KeyCap(label: 'Esc', onTap: () => _key(TerminalKey.escape)),
                _KeyCap(label: 'Tab', onTap: () => _key(TerminalKey.tab)),
                _KeyCap(
                  label: 'Ctrl',
                  active: session.modifiers.ctrl,
                  onTap: session.modifiers.toggleCtrl,
                ),
                _KeyCap(
                  label: 'Alt',
                  active: session.modifiers.alt,
                  onTap: session.modifiers.toggleAlt,
                ),
                _KeyCap(
                  label: 'Shift',
                  active: session.modifiers.shift,
                  onTap: session.modifiers.toggleShift,
                ),
                _KeyCap(label: '↑', onTap: () => _key(TerminalKey.arrowUp)),
                _KeyCap(label: '↓', onTap: () => _key(TerminalKey.arrowDown)),
                _KeyCap(label: '←', onTap: () => _key(TerminalKey.arrowLeft)),
                _KeyCap(label: '→', onTap: () => _key(TerminalKey.arrowRight)),
                _KeyCap(label: 'PgUp', onTap: () => _key(TerminalKey.pageUp)),
                _KeyCap(label: 'PgDn', onTap: () => _key(TerminalKey.pageDown)),
                _KeyCap(label: 'Home', onTap: () => _key(TerminalKey.home)),
                _KeyCap(label: 'End', onTap: () => _key(TerminalKey.end)),
                _KeyCap(label: 'Del', onTap: () => _key(TerminalKey.delete)),
                _KeyCap(label: '-', onTap: () => _text('-')),
                _KeyCap(label: '/', onTap: () => _text('/')),
                _KeyCap(label: '~', onTap: () => _text('~')),
                _KeyCap(label: '|', onTap: () => _text('|')),
                _KeyCap(
                  label: '复制',
                  onTap: hasSelection
                      ? () => _invoke(CopySelectionTextIntent.copy)
                      : null,
                ),
                _KeyCap(
                  label: '粘贴',
                  onTap: () => _invoke(
                    const PasteTextIntent(SelectionChangedCause.toolbar),
                  ),
                ),
                _KeyCap(
                  label: '键盘',
                  icon: Icons.keyboard_outlined,
                  onTap: () {
                    if (session.focusNode.hasFocus) {
                      session.focusNode.unfocus();
                    } else {
                      session.focusNode.requestFocus();
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({
    required this.label,
    required this.onTap,
    this.active = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final bg = active
        ? AppColors.accentSoft
        : (dark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh);
    final fg = active
        ? AppColors.accent
        : theme.colorScheme.onSurfaceVariant;
    final enabled = onTap != null;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.sm),
            child: Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: Space.x2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(
                  color: active ? AppColors.accent : Colors.transparent,
                ),
              ),
              child: icon != null
                  ? Icon(icon, size: 18, color: fg)
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
