import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm2/xterm.dart';

import '../../app/app.dart';
import '../../data/settings_repository.dart';
import '../../design/tokens.dart';
import '../../session/terminal_session.dart';
import '../../terminal/terminal_style.dart';
import '../../terminal/terminal_themes.dart';
import 'session_intents.dart';

/// The single place a `TerminalView` is instantiated.
///
/// Reusing the session's controllers/focus node and wrapping in a
/// `RepaintBoundary` keeps UI updates from disturbing terminal rendering, and
/// switching sessions preserves scrollback and scroll position because the
/// underlying `Terminal` object is unchanged.
class TerminalViewport extends StatefulWidget {
  const TerminalViewport({super.key, required this.session, required this.settings});

  final TerminalSession session;
  final AppSettings settings;

  @override
  State<TerminalViewport> createState() => _TerminalViewportState();
}

class _TerminalViewportState extends State<TerminalViewport> {
  bool _started = false;

  TerminalSession get _session => widget.session;

  @override
  void didUpdateWidget(TerminalViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) _started = false;
  }

  void _ensureStarted(BoxConstraints constraints) {
    if (_started) return;
    _started = true;
    final fontSize = widget.settings.terminalFontSize;
    final charWidth = fontSize * 0.6;
    final lineHeight = fontSize * 1.25;
    final cols = ((constraints.maxWidth - Space.x4) / charWidth).floor().clamp(20, 500);
    final rows = ((constraints.maxHeight - Space.x4) / lineHeight).floor().clamp(5, 300);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _session.start(width: cols, height: rows);
    });
  }

  Future<void> _showContextMenu(BuildContext context, Offset globalPosition) async {
    final anchor = _session.builderKey.currentContext;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final selection = _session.terminalController.selection;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );
    final action = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'copy',
          enabled: selection != null,
          child: const Text('复制'),
        ),
        const PopupMenuItem(value: 'paste', child: Text('粘贴')),
        const PopupMenuItem(value: 'selectAll', child: Text('全选')),
      ],
    );
    if (action == null || anchor == null || !anchor.mounted) return;
    switch (action) {
      case 'copy':
        Actions.invoke(anchor, CopySelectionTextIntent.copy);
      case 'paste':
        Actions.invoke(anchor, const PasteTextIntent(SelectionChangedCause.toolbar));
      case 'selectAll':
        Actions.invoke(anchor, const SelectAllTextIntent(SelectionChangedCause.toolbar));
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = ServicesScope.of(context).manager;
    final theme = kTerminalThemes[widget.settings.terminalThemeId]!;
    final style = terminalStyleFor(widget.settings.terminalFontSize);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _ensureStarted(constraints);
          return Actions(
            actions: <Type, Action<Intent>>{
              NextSessionIntent: CallbackAction<NextSessionIntent>(
                onInvoke: (_) {
                  manager.activateNext();
                  return null;
                },
              ),
              PrevSessionIntent: CallbackAction<PrevSessionIntent>(
                onInvoke: (_) {
                  manager.activatePrevious();
                  return null;
                },
              ),
              CloseActiveSessionIntent: CallbackAction<CloseActiveSessionIntent>(
                onInvoke: (_) {
                  if (manager.activeSessionId != null) {
                    manager.closeSession(manager.activeSessionId!);
                  }
                  return null;
                },
              ),
              CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(
                onInvoke: (_) async {
                  final selection =
                      _session.terminalController.selectionFor(_session.terminal.buffer);
                  if (selection == null) return null;
                  final text = _session.terminal.buffer.getText(selection, true);
                  await Clipboard.setData(ClipboardData(text: text));
                  return null;
                },
              ),
              PasteTextIntent: CallbackAction<PasteTextIntent>(
                onInvoke: (_) async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final text = data?.text;
                  if (text != null) {
                    _session.terminal.paste(text);
                    _session.terminalController.clearSelection();
                  }
                  return null;
                },
              ),
              SelectAllTextIntent: CallbackAction<SelectAllTextIntent>(
                onInvoke: (_) {
                  _session.terminalController.setSelection(
                    _session.terminal.buffer.createAnchor(0, 0),
                    _session.terminal.buffer.createAnchor(
                      _session.terminal.viewWidth,
                      _session.terminal.buffer.height - 1,
                    ),
                    mode: SelectionMode.line,
                  );
                  return null;
                },
              ),
            },
            child: Builder(
              key: _session.builderKey,
              builder: (context) => TerminalView(
                _session.terminal,
                controller: _session.terminalController,
                scrollController: _session.scrollController,
                focusNode: _session.focusNode,
                theme: theme,
                textStyle: style,
                autofocus: true,
                autoResize: true,
                backgroundOpacity: 1,
                padding: const EdgeInsets.all(Space.x2),
                shortcuts: {
                  ...defaultTerminalShortcuts,
                  const SingleActivator(LogicalKeyboardKey.pageDown, control: true):
                      const NextSessionIntent(),
                  const SingleActivator(LogicalKeyboardKey.pageUp, control: true):
                      const PrevSessionIntent(),
                  const SingleActivator(LogicalKeyboardKey.keyW, control: true):
                      const CloseActiveSessionIntent(),
                },
                onSecondaryTapDown: (details, offset) =>
                    _showContextMenu(context, details.globalPosition),
              ),
            ),
          );
        },
      ),
    );
  }
}
