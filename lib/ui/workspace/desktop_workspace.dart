import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../design/tokens.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/status_dot.dart';
import '../../session/terminal_session.dart';
import '../common/backup_actions.dart';
import '../servers/server_edit_page.dart';
import '../servers/server_tile.dart';
import '../settings/settings_page.dart';
import '../terminal/terminal_viewport.dart';

/// Desktop layout: a fixed server sidebar beside the session workspace.
class DesktopWorkspace extends StatelessWidget {
  const DesktopWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Row(
        children: [
          SizedBox(width: 280, child: _ServerSidebar()),
          VerticalDivider(width: 1),
          Expanded(child: _SessionWorkspace()),
        ],
      ),
    );
  }
}

class _ServerSidebar extends StatefulWidget {
  const _ServerSidebar();

  @override
  State<_ServerSidebar> createState() => _ServerSidebarState();
}

class _ServerSidebarState extends State<_ServerSidebar> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.manager, scope.servers]),
      builder: (context, _) {
        final servers = scope.servers.servers;
        final filtered = _query.isEmpty
            ? servers
            : servers.where((s) => _matches(s, _query)).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x2, Space.x2),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Termora',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                    ),
                  ),
                ],
              ),
            ),
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
              child: ListView(
                children: [
                  if (scope.manager.sessions.isNotEmpty) ...[
                    const _SideHeader('活动会话'),
                    for (final session in scope.manager.sessions)
                      _ActiveSessionRow(session: session),
                  ],
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(Space.x4),
                      child: Text('没有服务器', style: TextStyle(fontSize: 12)),
                    )
                  else ...[
                    const _SideHeader('服务器'),
                    for (final server in filtered) ServerTile(server: server),
                  ],
                  const SizedBox(height: Space.x6),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Space.x3),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const ServerEditPage()),
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
  List<BufferRangeLine> _matches = [];
  TerminalSession? _searchedSession;
  int _current = 0;

  @override
  void dispose() {
    _searchController.dispose();
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
        if (active == null) {
          return const EmptyState(
            icon: Icons.terminal,
            title: '没有活动会话',
            subtitle: '从左侧选择一个服务器开始连接',
          );
        }
        final showCount = _searchedSession == active;
        return Column(
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
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
                  SizedBox(
                    width: 240,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.x2),
                      child: TextField(
                        controller: _searchController,
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
                              Text(
                                showCount && _matches.isNotEmpty
                                    ? '${_current + 1}/${_matches.length}'
                                    : '',
                                style: const TextStyle(fontSize: 11),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_up, size: 16),
                                onPressed: () => _step(active, -1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                onPressed: () => _step(active, 1),
                              ),
                            ],
                          ),
                        ),
                        onChanged: (v) => _runSearch(active, v.trim()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TerminalViewport(
                session: active,
                settings: scope.settings.settings,
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
    return InkWell(
      onTap: () => manager.activate(session.id),
      child: Container(
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
            InkWell(
              onTap: () => manager.closeSession(session.id),
              child: const Icon(Icons.close, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
