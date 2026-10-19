import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../design/motion.dart';
import '../../design/overlays.dart';
import '../../design/palette.dart';
import '../../design/route.dart';
import '../../design/tokens.dart';
import '../../design/widgets/animated_diff_list.dart';
import '../../design/widgets/empty_state.dart';
import '../../design/widgets/enter_transition.dart';
import '../../design/widgets/link_indicator.dart';
import '../../design/widgets/link_pulse.dart';
import '../../design/widgets/mask_reveal.dart';
import '../../design/widgets/pressable.dart';
import '../../design/widgets/scroll.dart';
import '../../design/widgets/section_header.dart';
import '../../design/widgets/server_avatar.dart';
import '../../session/session_status.dart';
import '../../session/terminal_session.dart';
import '../common/backup_actions.dart';
import '../servers/server_edit_page.dart';
import '../servers/server_tile.dart';
import '../settings/settings_page.dart';
import '../terminal/terminal_page.dart';
import 'command_dock.dart';

/// A flattened home row: a stable [key] plus a builder that renders it.
class _HomeRow {
  _HomeRow(this.key, this.builder);

  final String key;
  final Widget Function(BuildContext context, int index) builder;
}

/// Mobile home page: active sessions, favorites, recents and grouped servers.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  final _lifted = ValueNotifier<bool>(false);
  bool _searching = false;
  String _query = '';

  /// Retains rows so a removed row can be rendered during its exit animation.
  final Map<String, _HomeRow> _rowCache = {};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _lifted.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final lifted = _scroll.offset > 8;
    if (_lifted.value != lifted) _lifted.value = lifted;
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

        final rows = _buildRows(scope, servers, filtered);
        for (final row in rows) {
          _rowCache[row.key] = row;
        }
        final listKey = ValueKey(_query.isEmpty ? 'home-all' : 'home-q:$_query');
        final connecting = scope.manager.sessions
            .any((s) => s.status == SessionStatus.connecting);

        return Scaffold(
          appBar: AppBar(
            title: _searching
                ? MaskReveal(
                    axis: Axis.horizontal,
                    open: true,
                    child: _searchField(context),
                  )
                : ValueListenableBuilder<bool>(
                    valueListenable: _lifted,
                    builder: (context, lifted, _) => lifted
                        ? const Text(
                            'Termora',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
            bottom: PreferredSize(
              preferredSize: const Size(0, 1),
              child: ValueListenableBuilder<bool>(
                valueListenable: _lifted,
                builder: (context, lifted, _) => AnimatedOpacity(
                  duration: Motion.control,
                  opacity: lifted ? 1 : 0,
                  child: LinkPulse(active: connecting, height: 1),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) {
                    _searchController.clear();
                    _query = '';
                  }
                }),
                icon: AnimatedSwitcher(
                  duration: Motion.tab,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    _searching ? Icons.close : Icons.search,
                    key: ValueKey(_searching),
                  ),
                ),
              ),
              if (!_searching)
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scroll,
                slivers: [
                  AnimatedDiffList(
                    key: listKey,
                    sliver: true,
                    keys: [for (final row in rows) row.key],
                    itemBuilder: (context, index, key, animation) =>
                        _rowCache[key]!.builder(context, index),
                    removedBuilder: (context, key, animation) =>
                        _rowCache[key]?.builder(context, 0) ??
                        const SizedBox.shrink(),
                  ),
                ],
              ),
              Positioned.fill(
                child: CommandDock(
                  primary: DockAction(
                    id: 'new',
                    icon: Icons.add,
                    label: '新增服务器',
                    onTap: () => _newServer(context),
                  ),
                  actions: [
                    DockAction(
                      id: 'import',
                      icon: Icons.file_upload_outlined,
                      label: '导入',
                      onTap: () => importBackup(context),
                    ),
                    DockAction(
                      id: 'export',
                      icon: Icons.file_download_outlined,
                      label: '导出',
                      onTap: () => exportBackup(context),
                    ),
                    DockAction(
                      id: 'settings',
                      icon: Icons.settings_outlined,
                      label: '设置',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsPage(),
                        ),
                      ),
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

  /// Builds the flattened, deduplicated rows: favorites win over recents, both
  /// win over groups and the ungrouped bucket.
  List<_HomeRow> _buildRows(
    ServicesScope scope,
    List<ServerConfig> servers,
    List<ServerConfig> filtered,
  ) {
    final rows = <_HomeRow>[];

    if (_query.isEmpty) {
      rows.add(_HomeRow('row:intro', (context, index) => const _HomeIntro()));
    }

    if (_query.isNotEmpty) {
      if (filtered.isEmpty) {
        rows.add(
          _HomeRow(
            'row:no-match',
            (context, index) => const Padding(
              padding: EdgeInsets.symmetric(vertical: Space.x10),
              child: EmptyState(icon: Icons.search_off, title: '没有匹配的服务器'),
            ),
          ),
        );
      } else {
        for (final server in filtered) {
          rows.add(_serverRow(server, animate: false));
        }
      }
      rows.add(_tailRow());
      return rows;
    }

    if (scope.manager.sessions.isNotEmpty) {
      rows.add(
        _HomeRow(
          'hdr:sessions',
          (context, index) => const SectionHeader(title: '活动会话'),
        ),
      );
      rows.add(
        _HomeRow(
          'row:sessions',
          (context, index) => _ActiveSessions(sessions: scope.manager.sessions),
        ),
      );
    }

    if (servers.isEmpty) {
      rows.add(
        _HomeRow(
          'row:empty',
          (context, index) => const Padding(
            padding: EdgeInsets.symmetric(vertical: Space.x10),
            child: EmptyState(
              icon: Icons.dns_outlined,
              title: '还没有服务器',
              subtitle: '添加一台服务器即可开始连接',
            ),
          ),
        ),
      );
      rows.add(_tailRow());
      return rows;
    }

    // Deduplicate: favorites > recents > groups > ungrouped.
    final favorites = scope.servers.favorites;
    final favIds = {for (final s in favorites) s.id};
    final recents = [
      for (final s in scope.servers.recents)
        if (!favIds.contains(s.id)) s,
    ];
    final shownIds = {...favIds, for (final s in recents) s.id};

    void section(String key, String title, List<ServerConfig> list) {
      rows.add(_HomeRow('hdr:$key', (context, index) => SectionHeader(title: title)));
      for (final server in list) {
        rows.add(_serverRow(server, animate: true));
      }
    }

    if (favorites.isNotEmpty) section('favorites', '收藏', favorites);
    if (recents.isNotEmpty) section('recents', '最近连接', recents);
    for (final group in scope.servers.groups) {
      final list = scope.servers
          .byGroup(group.id)
          .where((s) => !shownIds.contains(s.id))
          .toList();
      if (list.isNotEmpty) section('group:${group.id}', group.name, list);
    }
    final ungrouped = scope.servers
        .byGroup(null)
        .where((s) => !shownIds.contains(s.id))
        .toList();
    if (ungrouped.isNotEmpty) {
      if (scope.servers.groups.isNotEmpty) {
        rows.add(
          _HomeRow('hdr:ungrouped', (context, index) => const SectionHeader(title: '未分组')),
        );
      }
      for (final server in ungrouped) {
        rows.add(_serverRow(server, animate: true));
      }
    }

    rows.add(_tailRow());
    return rows;
  }

  _HomeRow _serverRow(ServerConfig server, {required bool animate}) => _HomeRow(
    'srv:${server.id}',
    (context, index) => EnterTransition(
      index: index,
      animate: animate,
      child: ServerTile(server: server),
    ),
  );

  _HomeRow _tailRow() =>
      _HomeRow('row:tail', (context, index) => const SizedBox(height: 112));

  Widget _searchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, Space.x2),
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
    final p = AppPalette.of(context);
    return SizedBox(
      height: 64,
      child: ScrollConfiguration(
        behavior: const HorizontalDragScrollBehavior(),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.x4),
          itemCount: sessions.length,
          itemBuilder: (context, i) {
            final session = sessions[i];
            return EnterTransition(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(right: Space.x2),
                child: Pressable(
                  onTap: () {
                    manager.activate(session.id);
                    Navigator.of(context).push(
                      terminalRoute<void>(
                        builder: (_) => TerminalPage(
                          sessionId: session.id,
                          heroTag: sessionHeroTag(session.id),
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _showSessionMenu(context, session),
                  child: SizedBox(
                    width: 152,
                    height: 64,
                    child: HoverSurface(
                      spotlight: true,
                      baseColor: Colors.transparent,
                      hoverColor: p.hoverOverlay,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: BorderSide(color: p.border),
                      hoverBorder: BorderSide(color: p.borderStrong),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                        child: Row(
                          children: [
                            ServerAvatar(
                              seed: session.server.name,
                              size: 32,
                              status: session.status,
                              heroTag: sessionHeroTag(session.id),
                            ),
                            const SizedBox(width: Space.x3),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.server.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      LinkIndicator(
                                        status: session.status,
                                        size: 6,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _statusLabel(session.status),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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
    await showAppSheet<void>(
      context,
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

/// The big hero title shown at the top of the mobile home list.
class _HomeIntro extends StatelessWidget {
  const _HomeIntro();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x4, Space.x2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Termora',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SSH 客户端',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    child: LinkPulse(active: true, color: p.accent, height: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
