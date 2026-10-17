import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../design/tokens.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/section_header.dart';
import '../../design/widgets/server_avatar.dart';
import '../../design/widgets/status_dot.dart';
import '../../session/session_status.dart';
import '../../session/terminal_session.dart';
import '../servers/server_edit_page.dart';
import '../servers/server_tile.dart';
import '../settings/settings_page.dart';
import '../terminal/terminal_page.dart';

/// Mobile home page: active sessions, favorites, recents and grouped servers.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  bool _searching = false;
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
      listenable: Listenable.merge([scope.manager, scope.servers, scope.settings]),
      builder: (context, _) {
        final servers = scope.servers.servers;
        final filtered = _query.isEmpty
            ? servers
            : servers.where((s) => _matches(s, _query)).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Termora',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                icon: Icon(_searching ? Icons.close : Icons.search),
                onPressed: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) {
                    _searchController.clear();
                    _query = '';
                  }
                }),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _newServer(context),
            icon: const Icon(Icons.add),
            label: const Text('新增服务器'),
          ),
          body: CustomScrollView(
            slivers: [
              if (_searching)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.x4,
                      Space.x2,
                      Space.x4,
                      Space.x2,
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '搜索名称、主机或用户名',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                      onChanged: (value) => setState(() => _query = value.trim()),
                    ),
                  ),
                ),
              if (_query.isNotEmpty)
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(icon: Icons.search_off, title: '没有匹配的服务器'),
                  )
                else
                  SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => ServerTile(server: filtered[i]),
                  )
              else ...[
                if (scope.manager.sessions.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SectionHeader(title: '活动会话')),
                  SliverToBoxAdapter(
                    child: _ActiveSessions(sessions: scope.manager.sessions),
                  ),
                ],
                if (servers.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.dns_outlined,
                      title: '还没有服务器',
                      subtitle: '添加一台服务器即可开始连接',
                      action: FilledButton.icon(
                        onPressed: () => _newServer(context),
                        icon: const Icon(Icons.add),
                        label: const Text('新增服务器'),
                      ),
                    ),
                  )
                else ...[
                  if (scope.servers.favorites.isNotEmpty) ...[
                    const SliverToBoxAdapter(child: SectionHeader(title: '收藏')),
                    SliverList.builder(
                      itemCount: scope.servers.favorites.length,
                      itemBuilder: (context, i) =>
                          ServerTile(server: scope.servers.favorites[i]),
                    ),
                  ],
                  if (scope.servers.recents.isNotEmpty) ...[
                    const SliverToBoxAdapter(child: SectionHeader(title: '最近连接')),
                    SliverList.builder(
                      itemCount: scope.servers.recents.length,
                      itemBuilder: (context, i) =>
                          ServerTile(server: scope.servers.recents[i]),
                    ),
                  ],
                  for (final group in scope.servers.groups)
                    if (scope.servers.byGroup(group.id).isNotEmpty) ...[
                      SliverToBoxAdapter(child: SectionHeader(title: group.name)),
                      SliverList.builder(
                        itemCount: scope.servers.byGroup(group.id).length,
                        itemBuilder: (context, i) =>
                            ServerTile(server: scope.servers.byGroup(group.id)[i]),
                      ),
                    ],
                  if (scope.servers.byGroup(null).isNotEmpty) ...[
                    if (scope.servers.groups.isNotEmpty)
                      const SliverToBoxAdapter(child: SectionHeader(title: '未分组')),
                    SliverList.builder(
                      itemCount: scope.servers.byGroup(null).length,
                      itemBuilder: (context, i) =>
                          ServerTile(server: scope.servers.byGroup(null)[i]),
                    ),
                  ],
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ],
          ),
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

  Future<void> _newServer(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ServerEditPage()),
    );
  }
}

class _ActiveSessions extends StatelessWidget {
  const _ActiveSessions({required this.sessions});

  final List<TerminalSession> sessions;

  @override
  Widget build(BuildContext context) {
    final manager = ServicesScope.of(context).manager;
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.x4),
        itemCount: sessions.length,
        itemBuilder: (context, i) {
          final session = sessions[i];
          return Padding(
            padding: const EdgeInsets.only(right: Space.x2),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.md),
              onTap: () {
                manager.activate(session.id);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TerminalPage(sessionId: session.id),
                  ),
                );
              },
              onLongPress: () => _showSessionMenu(context, session),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    ServerAvatar(seed: session.server.name, size: 32),
                    const SizedBox(width: Space.x3),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.server.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Row(
                          children: [
                            StatusDot(status: session.status, size: 6),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel(session.status),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(SessionStatus status) {
    return switch (status) {
      SessionStatus.connecting => '连接中',
      SessionStatus.connected => '已连接',
      SessionStatus.disconnected => '已断开',
      SessionStatus.failed => '失败',
    };
  }

  Future<void> _showSessionMenu(BuildContext context, TerminalSession session) async {
    final manager = ServicesScope.of(context).manager;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('断开连接'),
              onTap: () {
                session.disconnect();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('关闭会话'),
              onTap: () {
                manager.closeSession(session.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
