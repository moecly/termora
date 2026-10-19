import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../design/motion.dart';
import '../../design/palette.dart';
import '../../design/tokens.dart';
import '../../design/widgets/animated_diff_list.dart';
import '../../design/widgets/link_indicator.dart';
import '../../design/widgets/mask_reveal.dart';
import '../../design/widgets/pressable.dart';
import '../../design/widgets/server_avatar.dart';
import '../../session/terminal_session.dart';
import '../common/backup_actions.dart';
import '../servers/server_edit_page.dart';
import '../servers/server_tile.dart';

/// Which list the navigator panel shows.
enum NavigatorDestination { servers, sessions }

/// The middle navigator panel: a searchable server list or the session list.
class NavigatorPanel extends StatefulWidget {
  const NavigatorPanel({super.key, required this.destination});

  final NavigatorDestination destination;

  static const double width = 264;

  @override
  State<NavigatorPanel> createState() => _NavigatorPanelState();
}

class _NavigatorPanelState extends State<NavigatorPanel> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(ServerConfig server, String query) {
    final q = query.toLowerCase();
    return server.name.toLowerCase().contains(q) ||
        server.host.toLowerCase().contains(q) ||
        server.username.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    final p = AppPalette.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.manager, scope.servers]),
      builder: (context, _) {
        final servers = scope.servers.servers;
        final filtered = _query.isEmpty
            ? servers
            : servers.where((s) => _matches(s, _query)).toList();
        final showingServers = widget.destination == NavigatorDestination.servers;
        final keys = showingServers
            ? [
                if (filtered.isEmpty) 'row:none' else 'hdr:servers',
                for (final s in filtered) 'srv:${s.id}',
              ]
            : [
                if (scope.manager.sessions.isEmpty) 'row:none-sessions'
                else 'hdr:sessions',
                for (final s in scope.manager.sessions) 'ses:${s.id}',
              ];

        return Container(
          width: NavigatorPanel.width,
          color: p.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.x4),
                  child: Row(
                    children: [
                      Text(
                        showingServers ? '服务器' : '会话',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              if (showingServers)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索服务器',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 16),
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
                child: MaskReveal(
                  axis: Axis.horizontal,
                  duration: Motion.reveal,
                  open: true,
                  child: AnimatedDiffList(
                    key: ValueKey(widget.destination),
                    keys: keys,
                    padding: const EdgeInsets.only(bottom: Space.x3),
                    itemBuilder: (context, index, key, animation) =>
                        _buildItem(scope, key),
                    removedBuilder: (context, key, animation) =>
                        _buildItem(scope, key),
                  ),
                ),
              ),
              Divider(height: 1, color: p.border),
              if (showingServers)
                Padding(
                  padding: const EdgeInsets.all(Space.x3),
                  child: Column(
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
          ),
        );
      },
    );
  }

  Widget _buildItem(ServicesScope scope, String key) {
    if (key == 'row:none') {
      return const Padding(
        padding: EdgeInsets.all(Space.x4),
        child: Text('没有服务器', style: TextStyle(fontSize: 12)),
      );
    }
    if (key == 'row:none-sessions') {
      return const Padding(
        padding: EdgeInsets.all(Space.x4),
        child: Text('没有会话', style: TextStyle(fontSize: 12)),
      );
    }
    if (key.startsWith('srv:')) {
      final id = key.substring(4);
      final server = scope.servers.servers.firstWhere((s) => s.id == id);
      return ServerTile(server: server);
    }
    if (key.startsWith('ses:')) {
      final id = key.substring(4);
      final session = scope.manager.sessionById(id);
      if (session == null) return const SizedBox.shrink();
      return SessionTile(session: session);
    }
    return const SizedBox.shrink();
  }
}

/// A 44px session row for the navigator panel.
class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.session});

  final TerminalSession session;

  @override
  Widget build(BuildContext context) {
    final manager = ServicesScope.of(context).manager;
    final p = AppPalette.of(context);
    final active = manager.activeSessionId == session.id;
    final s = session.server;
    return HoverSurface(
      baseColor: active ? p.accentSoft : Colors.transparent,
      hoverColor: p.hoverOverlay,
      borderRadius: BorderRadius.zero,
      border: const BorderSide(color: Colors.transparent),
      hoverBorder: const BorderSide(color: Colors.transparent),
      onTap: () => manager.activate(session.id),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            AnimatedContainer(
              duration: Motion.control,
              width: 2,
              height: 44,
              color: active ? p.accent : Colors.transparent,
            ),
            const SizedBox(width: Space.x2),
            ServerAvatar(seed: s.name, size: 28, status: session.status),
            const SizedBox(width: Space.x2),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '${s.username}@${s.host}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            LinkIndicator(status: session.status, size: 8),
            const SizedBox(width: Space.x1),
            Pressable(
              onTap: () => manager.closeSession(session.id),
              child: const Padding(
                padding: EdgeInsets.all(Space.x1),
                child: Icon(Icons.close, size: 14),
              ),
            ),
            const SizedBox(width: Space.x2),
          ],
        ),
      ),
    );
  }
}
