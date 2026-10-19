import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import '../../design/motion.dart';
import '../../design/palette.dart';
import '../../design/tokens.dart';
import '../../design/widgets/link_pulse.dart';
import '../../design/widgets/mask_reveal.dart';
import '../../session/terminal_session.dart';

/// The on-screen key deck replacing the old helper bar: a persistent "peek"
/// row plus an expandable panel of extra keys, clipboard and focus controls.
class KeyDeck extends StatefulWidget {
  const KeyDeck({super.key, required this.session, this.collapsed = false});

  final TerminalSession session;

  /// When true the deck collapses to zero height (immersive mode).
  final bool collapsed;

  @override
  State<KeyDeck> createState() => _KeyDeckState();
}

class _KeyDeckState extends State<KeyDeck> with SingleTickerProviderStateMixin {
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: Motion.panel,
  );

  @override
  void dispose() {
    _expand.dispose();
    super.dispose();
  }

  void _settle(double target) {
    if (AppMotion.reduced(context)) {
      _expand.value = target;
      return;
    }
    _expand.animateWith(
      Motion.to(Motion.snap, from: _expand.value, to: target),
    );
  }

  void _toggle() => _settle(_expand.value > 0.5 ? 0 : 1);

  void _key(TerminalKey key) => widget.session.terminal.keyInput(key);

  void _text(String text) => widget.session.terminal.textInput(text);

  void _invoke(Intent intent) {
    final context = widget.session.builderKey.currentContext;
    if (context == null) return;
    Actions.invoke(context, intent);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return ListenableBuilder(
      listenable: Listenable.merge([
        session.modifiers,
        session.terminalController,
      ]),
      builder: (context, _) {
        final hasSelection = session.terminalController.selection != null;
        return AnimatedBuilder(
          animation: _expand,
          builder: (context, _) {
            final e = Motion.emphasized.transform(_expand.value);
            final height = widget.collapsed ? 0.0 : 52 + 124 * e;
            return SizedBox(
              height: height,
              child: ClipRect(
                child: Column(
                  children: [
                    SizedBox(
                      height: 52,
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
                          const Spacer(),
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
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _toggle,
                            onVerticalDragUpdate: (d) {
                              _expand.value =
                                  (_expand.value - d.delta.dy / 124).clamp(0, 1);
                            },
                            onVerticalDragEnd: (d) {
                              final v = d.primaryVelocity ?? 0;
                              _settle(
                                v < -250
                                    ? 1
                                    : (v > 250
                                        ? 0
                                        : (_expand.value > 0.4 ? 1 : 0)),
                              );
                            },
                            child: Tooltip(
                              message: _expand.value > 0.5 ? '收起按键' : '更多按键',
                              child: SizedBox(
                                width: 40,
                                height: 52,
                                child: Center(
                                  child: AnimatedRotation(
                                    turns: _expand.value * 0.5,
                                    duration: AppMotion.scale(context, Motion.panel),
                                    child: const Icon(Icons.keyboard_arrow_up, size: 20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: MaskReveal(
                        axis: Axis.vertical,
                        open: _expand.value > 0.5,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 62,
                              child: _row([
                                _KeyCap(label: '↑', onTap: () => _key(TerminalKey.arrowUp)),
                                _KeyCap(label: '↓', onTap: () => _key(TerminalKey.arrowDown)),
                                _KeyCap(label: '←', onTap: () => _key(TerminalKey.arrowLeft)),
                                _KeyCap(label: '→', onTap: () => _key(TerminalKey.arrowRight)),
                                _KeyCap(label: 'PgUp', onTap: () => _key(TerminalKey.pageUp)),
                                _KeyCap(label: 'PgDn', onTap: () => _key(TerminalKey.pageDown)),
                                _KeyCap(label: 'Home', onTap: () => _key(TerminalKey.home)),
                                _KeyCap(label: 'End', onTap: () => _key(TerminalKey.end)),
                                _KeyCap(label: 'Del', onTap: () => _key(TerminalKey.delete)),
                              ]),
                            ),
                            SizedBox(
                              height: 62,
                              child: _row([
                                _KeyCap(label: '-', onTap: () => _text('-')),
                                _KeyCap(label: '/', onTap: () => _text('/')),
                                _KeyCap(label: '~', onTap: () => _text('~')),
                                _KeyCap(label: '|', onTap: () => _text('|')),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _row(List<Widget> keys) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Space.x2),
      child: Row(children: keys),
    );
  }
}

class _KeyCap extends StatefulWidget {
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
  State<_KeyCap> createState() => _KeyCapState();
}

class _KeyCapState extends State<_KeyCap> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: Motion.press,
    value: 1,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _setPressed(bool down) {
    final target = down ? 0.92 : 1.0;
    if (AppMotion.reduced(context)) {
      _press.value = target;
      return;
    }
    _press.animateWith(
      Motion.to(Motion.snap, from: _press.value, to: target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppPalette.of(context);
    final enabled = widget.onTap != null;
    final bg = widget.active ? p.accentSoft : p.surfaceHigh;
    final fg = widget.active ? p.accent : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.4,
        duration: Motion.hover,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: widget.onTap,
          child: ScaleTransition(
            scale: _press,
            child: Container(
              constraints: const BoxConstraints(minWidth: 42, minHeight: 34),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: Space.x2),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(
                  color: widget.active ? p.accent : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.icon != null
                      ? Icon(widget.icon, size: 18, color: fg)
                      : Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: fg,
                          ),
                        ),
                  if (widget.active) ...[
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 24,
                      child: LinkPulse(active: true, color: p.accent, height: 2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
