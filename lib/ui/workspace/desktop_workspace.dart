import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app.dart';
import '../../design/motion.dart';
import '../servers/server_edit_page.dart';
import '../settings/settings_page.dart';
import 'command_palette.dart';
import 'inspector_panel.dart';
import 'navigator_panel.dart';
import 'rail.dart';
import 'stage.dart';

/// Desktop layout: Rail (56) · Navigator (0↔264) · Stage · Inspector (0↔320).
class DesktopWorkspace extends StatefulWidget {
  const DesktopWorkspace({super.key});

  @override
  State<DesktopWorkspace> createState() => _DesktopWorkspaceState();
}

class _DesktopWorkspaceState extends State<DesktopWorkspace> {
  final _navigatorOpen = ValueNotifier<bool>(true);
  final _destination =
      ValueNotifier<NavigatorDestination>(NavigatorDestination.servers);
  final _inspector = ValueNotifier<InspectorContent?>(null);

  @override
  void dispose() {
    _navigatorOpen.dispose();
    _destination.dispose();
    _inspector.dispose();
    super.dispose();
  }

  void _openInspector(InspectorContent content) {
    if (MediaQuery.sizeOf(context).width < 1180) {
      _navigatorOpen.value = false;
    }
    _inspector.value = content;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            _navigatorOpen.value = !_navigatorOpen.value,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            showCommandPalette(
              context,
              onOpenThemeInspector: () =>
                  _openInspector(const TerminalThemeInspector()),
            ),
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
            _destination.value = NavigatorDestination.servers,
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
            _destination.value = NavigatorDestination.sessions,
        const SingleActivator(
          LogicalKeyboardKey.keyI,
          control: true,
          shift: true,
        ): () =>
            _inspector.value =
                _inspector.value == null ? const TerminalThemeInspector() : null,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _navigatorOpen,
                builder: (context, open, _) => ValueListenableBuilder<
                    NavigatorDestination>(
                  valueListenable: _destination,
                  builder: (context, destination, _) => WorkspaceRail(
                    destination: destination,
                    onDestinationChanged: (d) {
                      _destination.value = d;
                      _navigatorOpen.value = true;
                    },
                    navigatorOpen: open,
                    onToggleNavigator: () =>
                        _navigatorOpen.value = !_navigatorOpen.value,
                    sessionCount: ServicesScope.of(context).manager.sessions.length,
                    onNewServer: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ServerEditPage(),
                      ),
                    ),
                    onOpenPalette: () => showCommandPalette(
                      context,
                      onOpenThemeInspector: () =>
                          _openInspector(const TerminalThemeInspector()),
                    ),
                    onOpenSettings: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _navigatorOpen,
                builder: (context, open, _) => _AnimatedWidth(
                  target: open ? NavigatorPanel.width : 0,
                  child: ValueListenableBuilder<NavigatorDestination>(
                    valueListenable: _destination,
                    builder: (context, destination, _) =>
                        NavigatorPanel(destination: destination),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: SessionStage(
                  onSearchResults: (session, matches) => _openInspector(
                    SearchResultsInspector(session: session, matches: matches),
                  ),
                  onOpenServerInspector: (session) =>
                      _openInspector(ServerInspector(session: session)),
                  onOpenThemeInspector: () =>
                      _openInspector(const TerminalThemeInspector()),
                ),
              ),
              ValueListenableBuilder<InspectorContent?>(
                valueListenable: _inspector,
                builder: (context, content, _) => _AnimatedWidth(
                  target: content != null ? InspectorPanel.width : 0,
                  child: InspectorPanel(
                    content: content,
                    onClose: () => _inspector.value = null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animates a panel between [target] and 0 width. The child is laid out at its
/// natural (target) size and only the clip width changes, so no per-frame
/// re-layout of panel contents happens.
class _AnimatedWidth extends StatelessWidget {
  const _AnimatedWidth({required this.target, required this.child});

  final double target;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) {
      return SizedBox(width: target, child: target == 0 ? null : child);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: target),
      duration: Motion.spatial,
      curve: Motion.emphasized,
      child: child,
      builder: (context, w, child) => SizedBox(
        width: w,
        child: ClipRect(
          child: OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: w < 8 ? null : child,
          ),
        ),
      ),
    );
  }
}
