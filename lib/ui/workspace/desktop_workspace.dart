import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../design/motion.dart';
import '../../design/tokens.dart';
import '../../design/widgets/animated_diff_list.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/pressable.dart';
import '../../design/widgets/scroll.dart';
import '../../design/widgets/status_dot.dart';
import '../../session/terminal_session.dart';
import '../common/backup_actions.dart';
import '../servers/server_edit_page.dart';
import '../servers/server_tile.dart';
import '../settings/settings_page.dart';
import '../terminal/terminal_viewport.dart';

/// A flattened sidebar row: a stable [key] plus a builder.
class _SideRow {
  _SideRow(this.key, this.builder);

  final String key;
  final Widget Function(BuildContext context) builder;
}

/// Desktop layout: a collapsible server sidebar beside the session workspace.
class DesktopWorkspace extends StatefulWidget {
  const DesktopWorkspace({super.key});

  @override
  State<DesktopWorkspace> createState() => _DesktopWorkspaceState();
}

class _DesktopWorkspaceState extends State<DesktopWorkspace> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _collapsed ? 1 : 0),
            duration: Motion.spatial,
            curve: Motion.emphasized,
            builder: (context, t, _) => SizedBox(
              key: const ValueKey('server-sidebar'),
              width: 280 + (64 - 280) * t,
              child: _ServerSidebar(
                collapsed: t > 0.45,
                onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          const Expanded(child: _SessionWorkspace()),
        ],
      ),
    );
  }
}

class _ServerSidebar extends StatefulWidget {
  const _ServerSidebar({required this.collapsed, required this.onToggleCollapse});

  final bool collapsed;
  final VoidCallback onToggleCollapse;

  @override
  State<_ServerSidebar> createState() => _ServerSidebarState();
}

class _ServerSidebarState extends State<_ServerSidebar> {
  final _searchController = TextEditingController();
  final Map<String, _SideRow> _rowCache = {};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    final collapsed = widget.collapsed;
    return ListenableBuilder(
      listenable: Listenable.merge([scope.manager, scope.servers]),
      builder: (context, _) {
        final servers = scope.servers.servers;
        final filtered = _query.isEmpty
            ? servers
            : servers.where((s) => _matches(s, _query)).toList();

        final rows = _buildRows(scope, filtered, collapsed);
        for (final row in rows) {
          _rowCache[row.key] = row;
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                collapsed ? Space.x2 : Space.x4,
                Space.x4,
                Space.x2,
                Space.x2,
              ),
              child: Row(
                mainAxisAlignment:
                    collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  if (!collapsed)
                    const Expanded(
                      child: Text(
                        'Termora',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  AnimatedRotation(
                    turns: collapsed ? 0.5 : 0,
                    duration: Motion.panel,
                    curve: Motion.emphasized,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, size: 18),
                      tooltip: collapsed ? '展开侧栏' : '折叠侧栏',
                      onPressed: widget.onToggleCollapse,
                    ),
                  ),
                  if (!collapsed)
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                      ),
                    ),
                ],
              ),
            ),
            if (collapsed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                child: IconButton(
                  icon: const Icon(Icons.search, size: 18),
                  tooltip: '搜索服务器',
                  onPressed: widget.onToggleCollapse,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索服务器',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
            const SizedBox(height: Space.x2),
            Expanded(
              child: AnimatedDiffList(
                keys: [for (final row in rows) row.key],
                padding: const EdgeInsets.only(bottom: Space.x6),
                itemBuilder: (context, index, key, animation) =>
                    _rowCache[key]!.builder(context),
                removedBuilder: (context, key, animation) =>
                    _rowCache[key]?.builder(context) ?? const SizedBox.shrink(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Space.x3),
              child: collapsed
                  ? Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          tooltip: '新增服务器',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ServerEditPage(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.file_upload_outlined, size: 18),
                          tooltip: '导入',
                          onPressed: () => importBackup(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.file_download_outlined, size: 18),
                          tooltip: '导出',
                          onPressed: () => exportBackup(context),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ServerEditPage(),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('新增服务器'),
                          ),
                        ),
                        const SizedBox(height: Space.x2),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => importBackup(context),
                                child: const Text('导入'),
                              ),
                            ),
                            Expanded(
                              child: TextButton(
                                onPressed: () => exportBackup(context),
                                child: const Text('导出'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  List<_SideRow> _buildRows(
    ServicesScope scope,
    List<ServerConfig> filtered,
    bool collapsed,
  ) {
    final rows = <_SideRow>[];
    if (scope.manager.sessions.isNotEmpty) {
      if (!collapsed) {
        rows.add(_SideRow('hdr:sessions', (context) => const _SideHeader('活动会话')));
      }
      for (final session in scope.manager.sessions) {
        rows.add(
          _SideRow(
            'ses:${session.id}',
            (context) => _ActiveSessionRow(session: session),
          ),
        );
      }
    }
    if (filtered.isEmpty) {
      rows.add(
        _SideRow(
          'row:none',
          (context) => const Padding(
            padding: EdgeInsets.all(Space.x4),
            child: Text('没有服务器', style: TextStyle(fontSize: 12)),
          ),
        ),
      );
    } else {
      if (!collapsed) {
        rows.add(_SideRow('hdr:servers', (context) => const _SideHeader('服务器')));
      }
      for (final server in filtered) {
        rows.add(
          _SideRow(
            'srv:${server.id}',
            (context) => ServerTile(server: server, compact: collapsed),
          ),
        );
      }
    }
    return rows;
  }

  bool _matches(ServerConfig server, String query) {
    final q = query.toLowerCase();
    return server.name.toLowerCase().contains(q) ||
        server.host.toLowerCase().contains(q) ||
        server.username.toLowerCase().contains(q);
  }
}

class _SideHeader extends StatelessWidget {
  const _SideHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x4, Space.x2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ActiveSessionRow extends StatelessWidget {
  const _ActiveSessionRow({required this.session});
  final TerminalSession session;

  @override
  Widget build(BuildContext context) {
    final manager = ServicesScope.of(context).manager;
    final active = manager.activeSessionId == session.id;
    return ListTile(
      dense: true,
      selected: active,
      leading: StatusDot(status: session.status, size: 8),
      title: Text(session.server.name, style: const TextStyle(fontSize: 13)),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 16),
        onPressed: () => manager.closeSession(session.id),
      ),
      onTap: () => manager.activate(session.id),
    );
  }
}

class _SessionWorkspace extends StatefulWidget {
  const _SessionWorkspace();

  @override
  State<_SessionWorkspace> createState() => _SessionWorkspaceState();
}

class _SessionWorkspaceState extends State<_SessionWorkspace> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<BufferRangeLine> _matches = [];
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
        _matches = [];
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
    setState(() {
      _matches = ranges;
      _searchedSession = session;
      _current = 0;
    });
  }

  void _step(TerminalSession session, int delta) {
    if (_matches.isEmpty) return;
    final next = (_current + delta + _matches.length) % _matches.length;
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
        final countText = showCount && _matches.isNotEmpty
            ? '${_current + 1}/${_matches.length}'
            : '';
        return Column(
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: const HorizontalDragScrollBehavior(),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final session in manager.sessions)
                              _SessionTab(
                                session: session,
                                active: session.id == manager.activeSessionId,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.x2),
                      child: AnimatedContainer(
                        duration: Motion.hover,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Radii.md),
                          boxShadow: _searchFocus.hasFocus
                              ? AppShadows.of(
                                  Theme.of(context).brightness,
                                  1,
                                )
                              : const <BoxShadow>[],
                        ),
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
                                  onPressed: () {
                                    final s = active;
                                    if (s != null) _step(s, -1);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                  onPressed: () {
                                    final s = active;
                                    if (s != null) _step(s, 1);
                                  },
                                ),
                              ],
                            ),
                          ),
                          onChanged: (v) {
                            final s = active;
                            if (s != null) _runSearch(s, v.trim());
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: PageTransitionSwitcher(
                duration: Motion.tab,
                transitionBuilder: (child, primary, secondary) => FadeThroughTransition(
                  animation: primary,
                  secondaryAnimation: secondary,
                  child: child,
                ),
                child: active == null
                    ? const EmptyState(
                        key: ValueKey('workspace-empty'),
                        icon: Icons.terminal,
                        title: '没有活动会话',
                        subtitle: '从左侧选择一个服务器开始连接',
                      )
                    : TerminalViewport(
                        key: const ValueKey('workspace-pane'),
                        session: active,
                        settings: scope.settings.settings,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SessionTab extends StatelessWidget {
  const _SessionTab({required this.session, required this.active});
  final TerminalSession session;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final manager = ServicesScope.of(context).manager;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hoverOverlay =
        dark ? AppColors.darkHoverOverlay : AppColors.lightHoverOverlay;
    return HoverSurface(
      baseColor: Colors.transparent,
      hoverColor: hoverOverlay,
      borderRadius: BorderRadius.circular(Radii.sm),
      border: const BorderSide(color: Colors.transparent),
      hoverBorder: const BorderSide(color: Colors.transparent),
      onTap: () => manager.activate(session.id),
      child: AnimatedContainer(
        duration: Motion.tab,
        curve: Motion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: Space.x3),
        decoration: BoxDecoration(
          color: active ? scheme.surfaceContainerHighest : null,
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: active ? AppColors.accent : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            StatusDot(status: session.status, size: 6),
            const SizedBox(width: Space.x2),
            Text(session.server.name, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: Space.x2),
            Pressable(
              onTap: () => manager.closeSession(session.id),
              child: const Icon(Icons.close, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
