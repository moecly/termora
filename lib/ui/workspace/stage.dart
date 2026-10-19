import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../design/motion.dart';
import '../../design/palette.dart';
import '../../design/tokens.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/link_pulse.dart';
import '../../design/widgets/server_avatar.dart';
import '../../session/session_status.dart';
import '../../session/terminal_session.dart';
import '../../terminal/terminal_themes.dart';
import '../servers/server_tile.dart';
import '../terminal/connect_sequence.dart';
import '../terminal/session_banner.dart';
import '../terminal/terminal_viewport.dart';
import 'session_strip.dart';

/// The central stage: session strip, terminal pane and overlays.
class SessionStage extends StatefulWidget {
  const SessionStage({
    super.key,
    required this.onSearchResults,
    required this.onOpenServerInspector,
    required this.onOpenThemeInspector,
  });

  final void Function(TerminalSession session, List<TerminalSearchMatch> matches)
      onSearchResults;
  final void Function(TerminalSession session) onOpenServerInspector;
  final VoidCallback onOpenThemeInspector;

  @override
  State<SessionStage> createState() => _SessionStageState();
}

class _SessionStageState extends State<SessionStage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<BufferRangeLine> _ranges = [];
  TerminalSession? _searchedSession;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _runSearch(TerminalSession session, String query) {
    if (query.isEmpty) {
      session.terminalController.clearSearchHighlights();
      setState(() {
        _ranges = [];
        _searchedSession = session;
      });
      return;
    }
    final results = session.terminal.search(query);
    final ranges = [for (final m in results) m.range];
    session.terminalController.setSearchHighlights(
      session.terminal.buffer,
      ranges,
      currentIndex: 0,
    );
    widget.onSearchResults(session, results);
    setState(() {
      _ranges = ranges;
      _searchedSession = session;
      _current = 0;
    });
  }

  void _step(TerminalSession session, int delta) {
    if (_ranges.isEmpty) return;
    final next = (_current + delta + _ranges.length) % _ranges.length;
    session.terminalController.setCurrentSearchHighlight(next);
    setState(() => _current = next);
  }

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.manager, scope.settings]),
      builder: (context, _) {
        final manager = scope.manager;
        final active = manager.active;
        final showCount = _searchedSession == active;
        final countText = showCount && _ranges.isNotEmpty
            ? '${_current + 1}/${_ranges.length}'
            : '';
        final p = AppPalette.of(context);
        return Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  const Expanded(child: SessionStrip()),
                  SizedBox(
                    width: 240,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.x2),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        decoration: InputDecoration(
                          hintText: '搜索',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: Space.x2,
                            vertical: Space.x1,
                          ),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: Motion.control,
                                child: Text(
                                  countText,
                                  key: ValueKey(countText),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_up, size: 16),
                                onPressed: active == null
                                    ? null
                                    : () => _step(active, -1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                onPressed: active == null
                                    ? null
                                    : () => _step(active, 1),
                              ),
                            ],
                          ),
                        ),
                        onChanged: (v) {
                          if (active != null) _runSearch(active, v.trim());
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '服务器信息',
                    icon: const Icon(Icons.info_outline, size: 18),
                    onPressed:
                        active == null ? null : () => widget.onOpenServerInspector(active),
                  ),
                  IconButton(
                    tooltip: '终端配色',
                    icon: const Icon(Icons.palette_outlined, size: 18),
                    onPressed: widget.onOpenThemeInspector,
                  ),
                ],
              ),
            ),
            LinkPulse(
              active: active?.status == SessionStatus.connecting,
              height: 2,
              intensity: 0.8,
            ),
            Divider(height: 1, color: p.border),
            Expanded(
              child: Stack(
                children: [
                  PageTransitionSwitcher(
                    duration: Motion.tab,
                    transitionBuilder: (child, primary, secondary) =>
                        FadeThroughTransition(
                      animation: primary,
                      secondaryAnimation: secondary,
                      child: child,
                    ),
                    child: active == null
                        ? const _EmptyStage(key: ValueKey('stage-empty'))
                        : TerminalViewport(
                            key: ValueKey('stage-${active.id}'),
                            session: active,
                            settings: scope.settings.settings,
                          ),
                  ),
                  if (active != null &&
                      active.status == SessionStatus.connecting)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: kTerminalThemes[
                                  scope.settings.settings.terminalThemeId]!
                              .background,
                          child: ConnectSequence(session: active),
                        ),
                      ),
                    ),
                  if (active != null &&
                      (active.status == SessionStatus.failed ||
                          active.status == SessionStatus.disconnected))
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SessionBanner(session: active),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyStage extends StatelessWidget {
  const _EmptyStage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    final recents = scope.servers.recents.take(6).toList();
    final p = AppPalette.of(context);
    return Column(
      children: [
        const Expanded(
          child: EmptyState(
            icon: Icons.terminal,
            title: '没有活动会话',
            subtitle: '从左侧选择一个服务器开始连接',
          ),
        ),
        if (recents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x8),
            child: Wrap(
              spacing: Space.x2,
              runSpacing: Space.x2,
              alignment: WrapAlignment.center,
              children: [
                for (final server in recents)
                  _QuickTile(server: server),
              ],
            ),
          ),
        const SizedBox(height: Space.x3),
        Text(
          '按 Ctrl+K 打开命令面板',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: p.textTertiary),
        ),
        const SizedBox(height: Space.x6),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.server});

  final ServerConfig server;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: () => openSession(context, server),
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(Space.x3),
        decoration: BoxDecoration(
          color: p.surfaceHigh,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServerAvatar(seed: server.name, size: 32),
            const SizedBox(height: Space.x2),
            Text(
              server.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              server.host,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
