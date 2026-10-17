import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../design/motion.dart';
import '../../design/overlays.dart';
import '../../design/route.dart';
import '../../design/tokens.dart';
import '../../design/widgets/pressable.dart';
import '../../design/widgets/server_avatar.dart';
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
///
/// In [compact] mode only a centered avatar is rendered (collapsed sidebar).
class ServerTile extends StatefulWidget {
  const ServerTile({super.key, required this.server, this.compact = false});

  final ServerConfig server;
  final bool compact;

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
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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
    if (widget.compact) return _buildCompact(context);
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    return Tooltip(
      message: server.name,
      child: Pressable(
        onTap: _connecting ? null : () => _connect(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x2),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ServerAvatar(
                  seed: server.name,
                  size: 32,
                  heroTag: serverHeroTag(server.id),
                ),
                if (_connecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final borderStrong =
        dark ? AppColors.darkBorderStrong : AppColors.lightBorderStrong;
    final hoverOverlay =
        dark ? AppColors.darkHoverOverlay : AppColors.lightHoverOverlay;
    final subtitle = '${server.username}@${server.host}:${server.port}';

    final row = HoverSurface(
      baseColor: Colors.transparent,
      hoverColor: hoverOverlay,
      borderRadius: BorderRadius.circular(Radii.md),
      border: const BorderSide(color: Colors.transparent),
      hoverBorder: BorderSide(color: borderStrong),
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
              heroTag: serverHeroTag(server.id),
            ),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (server.note != null && server.note!.isNotEmpty)
                    Text(
                      server.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: server.favorite ? '取消收藏' : '收藏',
              onPressed: () => _favorite(context),
              icon: AnimatedSwitcher(
                duration: Motion.control,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  server.favorite ? Icons.star : Icons.star_border,
                  key: ValueKey(server.favorite),
                  size: 18,
                  color: server.favorite
                      ? AppColors.warning
                      : theme.colorScheme.onSurfaceVariant,
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
                    if (!_connecting) await openSession(context, server, force: true);
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

    return Opacity(
      opacity: _connecting ? 0.7 : 1,
      child: Stack(
        children: [
          row,
          if (_connecting)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
