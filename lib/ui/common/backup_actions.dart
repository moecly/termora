import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../data/backup_codec.dart';
import '../../data/backup_io.dart';
import '../../data/server_repository.dart';

String _triple(String host, int port, String username) =>
    '$host\u0000$port\u0000$username';

/// Exports servers (and optionally secrets) to a backup file.
///
/// Always asks whether to include plaintext secrets (default off), and asks a
/// second time before including them.
Future<void> exportBackup(BuildContext context) async {
  final scope = ServicesScope.of(context);
  var includeSecrets = false;

  final proceed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('导出配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: includeSecrets,
              onChanged: (v) => setState(() => includeSecrets = v),
              title: const Text('包含密码与私钥（明文）'),
            ),
            const SizedBox(height: 8),
            Text(
              '开启后导出的 JSON 文件中密码与私钥为明文，请妥善保管。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('导出'),
          ),
        ],
      ),
    ),
  );
  if (proceed != true || !context.mounted) return;

  if (includeSecrets) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认导出明文凭证'),
        content: const Text('导出的文件将包含明文密码/私钥，确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
  }

  Map<String, String>? secrets;
  if (includeSecrets) {
    secrets = {};
    for (final server in scope.servers.servers) {
      for (final key in secretKeysFor(server.id)) {
        final value = await scope.secretStore.read(key);
        if (value != null && value.isNotEmpty) secrets[key] = value;
      }
    }
  }

  final json = BackupCodec.encode(
    servers: scope.servers.servers,
    groups: scope.servers.groups,
    secrets: secrets,
  );

  try {
    final result = await BackupIo.export(json);
    if (result == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.shared ? '已调起分享' : '已保存到 ${result.path}',
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('导出失败：$error')),
    );
  }
}

/// Imports servers from a backup file, skipping duplicates.
Future<void> importBackup(BuildContext context) async {
  final scope = ServicesScope.of(context);
  String? text;
  try {
    text = await BackupIo.pickImportText();
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('读取文件失败：$error')),
    );
    return;
  }
  if (text == null) return;

  final BackupData data;
  try {
    data = BackupCodec.decode(text);
  } on FormatException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
    return;
  }

  final existing = scope.servers.servers
      .map((s) => _triple(s.host, s.port, s.username))
      .toSet();
  final addedIds = <String>{};
  for (final server in data.servers) {
    final key = _triple(server.host, server.port, server.username);
    if (existing.add(key)) addedIds.add(server.id);
  }

  final added = await scope.servers.importAll(data.servers, data.groups);
  for (final entry in data.secrets.entries) {
    final parts = entry.key.split(':');
    if (parts.length == 2 && addedIds.contains(parts[1])) {
      await scope.secretStore.write(entry.key, entry.value);
    }
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('新增 $added 台服务器，跳过 ${data.servers.length - added} 台已存在'),
    ),
  );
}
