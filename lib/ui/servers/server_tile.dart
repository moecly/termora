import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app.dart';
import '../../data/models.dart';
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
    MaterialPageRoute<void>(
      builder: (_) => TerminalPage(sessionId: session.id),
    ),
  );
}

/// A single server row with a trailing action menu.
class ServerTile extends StatelessWidget {
  const ServerTile({super.key, required this.server});

  final ServerConfig server;

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
    final confirmed = await showDialog<bool>(
      context: context,
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
    final theme = Theme.of(context);
    final subtitle = '${server.username}@${server.host}:${server.port}';

    return ListTile(
      leading: ServerAvatar(seed: server.name),
      title: Text(
        server.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      onTap: () => openSession(context, server),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          switch (value) {
            case 'connect':
              await openSession(context, server);
            case 'newSession':
              await openSession(context, server, force: true);
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
    );
  }
}
