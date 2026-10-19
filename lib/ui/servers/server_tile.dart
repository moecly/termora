import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../design/motion.dart';
import '../../design/overlays.dart';
import '../../design/palette.dart';
import '../../design/route.dart';
import '../../design/tokens.dart';
import '../../design/widgets/link_indicator.dart';
import '../../design/widgets/link_pulse.dart';
import '../../design/widgets/pressable.dart';
import '../../design/widgets/server_avatar.dart';
import '../../session/session_status.dart';
import '../terminal/terminal_page.dart';
import 'server_edit_page.dart';

/// Opens a terminal for [server], creating a session first.
Future<void> openSession(
  BuildContext context,
  ServerConfig server, {
  bool force = false,
}) async {
  final scope = ServicesScope.of(context);
  final session = await scope.manager.connect(server, force: force);
  if (!context.mounted) return;
  await Navigator.of(context).push(
    terminalRoute<void>(
      builder: (_) => TerminalPage(
        sessionId: session.id,
        heroTag: serverHeroTag(server.id),
      ),
    ),
  );
}

/// A single server row with a favorite toggle and a trailing action menu.
class ServerTile extends StatefulWidget {
  const ServerTile({super.key, required this.server});

  final ServerConfig server;

  @override
  State<ServerTile> createState() => _ServerTileState();
}

class _ServerTileState extends State<ServerTile> {
  bool _connecting = false;

  ServerConfig get server => widget.server;

  Future<void> _connect(BuildContext context) async {
    if (_connecting) return;
    setState(() => _connecting = true);
    try {
      await openSession(context, server);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _favorite(BuildContext context) async {
    final scope = ServicesScope.of(context);
    await scope.servers.upsert(server.copyWith(favorite: !server.favorite));
  }

  Future<void> _copyAddress(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: '${server.username}@${server.host}:${server.port}'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制地址')),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final scope = ServicesScope.of(context);
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (context) => AlertDialog(
        title: const Text('删除服务器'),
        content: Text('确定要删除「${server.name}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) await scope.servers.remove(server.id);
  }

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ServerEditPage(server: server)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppPalette.of(context);
    final manager = ServicesScope.of(context).manager;
    SessionStatus? activeStatus;
    for (final s in manager.sessions) {
      if (s.server.id == server.id) {
        activeStatus = s.status;
        break;
      }
    }
    final subtitle = '${server.username}@${server.host}:${server.port}';

    final row = HoverSurface(
      spotlight: true,
      baseColor: Colors.transparent,
      hoverColor: p.hoverOverlay,
      borderRadius: BorderRadius.circular(Radii.md),
      border: const BorderSide(color: Colors.transparent),
      hoverBorder: BorderSide(color: p.borderStrong),
      onTap: _connecting ? null : () => _connect(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x3,
          vertical: Space.x2,
        ),
        child: Row(
          children: [
            ServerAvatar(
              seed: server.name,
              size: 40,
              status: activeStatus,
              heroTag: serverHeroTag(server.id),
            ),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          server.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (activeStatus != null) ...[
                        const SizedBox(width: Space.x2),
                        LinkIndicator(status: activeStatus, size: 8),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: p.textSecondary,
                    ),
                  ),
                  if (server.note != null && server.note!.isNotEmpty)
                    Text(
                      server.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: server.favorite ? '取消收藏' : '收藏',
              onPressed: () => _favorite(context),
              icon: AnimatedScale(
                scale: server.favorite ? 1.15 : 1,
                duration: Motion.control,
                curve: Motion.emphasized,
                child: Icon(
                  server.favorite ? Icons.star : Icons.star_border,
                  size: 18,
                  color: server.favorite ? p.warn : p.textSecondary,
                ),
              ),
            ),
            PopupMenuButton<String>(
              popUpAnimationStyle: AppMotion.style(
                context,
                duration: Motion.overlay,
                reverseDuration: Motion.press,
              ),
              onSelected: (value) async {
                switch (value) {
                  case 'connect':
                    await _connect(context);
                  case 'newSession':
                    if (!_connecting) {
                      await openSession(context, server, force: true);
                    }
                  case 'edit':
                    await _edit(context);
                  case 'favorite':
                    await _favorite(context);
                  case 'copy':
                    await _copyAddress(context);
                  case 'delete':
                    await _delete(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'connect', child: Text('连接')),
                const PopupMenuItem(value: 'newSession', child: Text('新建会话')),
                const PopupMenuItem(value: 'edit', child: Text('编辑')),
                PopupMenuItem(
                  value: 'favorite',
                  child: Text(server.favorite ? '取消收藏' : '收藏'),
                ),
                const PopupMenuItem(value: 'copy', child: Text('复制地址')),
                const PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            ),
          ],
        ),
      ),
    );

    return Stack(
      children: [
        AnimatedOpacity(
          opacity: _connecting ? 0.7 : 1,
          duration: Motion.control,
          child: row,
        ),
        if (_connecting)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LinkPulse(active: true, height: 2),
          ),
      ],
    );
  }
}
