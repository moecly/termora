import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import '../../app/app.dart';
import '../../data/key_mapping.dart';
import '../../data/settings_repository.dart';
import '../../design/tokens.dart';
import '../../terminal/terminal_themes.dart';
import '../common/backup_actions.dart';

const String kAppVersion = '1.0.0+1';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    return ListenableBuilder(
      listenable: scope.settings,
      builder: (context, _) {
        final settings = scope.settings.settings;
        return Scaffold(
          appBar: AppBar(title: const Text('设置')),
          body: ListView(
            children: [
              _header(context, '外观'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x4),
                child: SegmentedButton<ThemeSetting>(
                  segments: const [
                    ButtonSegment(value: ThemeSetting.system, label: Text('跟随系统')),
                    ButtonSegment(value: ThemeSetting.light, label: Text('浅色')),
                    ButtonSegment(value: ThemeSetting.dark, label: Text('深色')),
                  ],
                  selected: {settings.theme},
                  onSelectionChanged: (s) =>
                      scope.settings.update(settings.copyWith(theme: s.first)),
                ),
              ),
              _header(context, '终端'),
              ListTile(
                title: const Text('字号'),
                subtitle: Slider(
                  min: kTerminalFontSizeMin,
                  max: kTerminalFontSizeMax,
                  divisions: 20,
                  value: settings.terminalFontSize,
                  label: '${settings.terminalFontSize.round()} pt',
                  onChanged: (v) =>
                      scope.settings.update(settings.copyWith(terminalFontSize: v)),
                ),
                trailing: Text(
                  '${settings.terminalFontSize.round()} pt',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Space.x4),
                child: Text('配色'),
              ),
              RadioGroup<String>(
                groupValue: settings.terminalThemeId,
                onChanged: (value) {
                  if (value != null) {
                    scope.settings.update(settings.copyWith(terminalThemeId: value));
                  }
                },
                child: Column(
                  children: [
                    for (final entry in kTerminalThemes.entries)
                      RadioListTile<String>(
                        value: entry.key,
                        title: Text(kTerminalThemeLabels[entry.key] ?? entry.key),
                        secondary: _swatch(entry.value),
                      ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('回滚行数'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Slider(
                      min: 1000,
                      max: 20000,
                      divisions: 19,
                      value: settings.scrollbackLines.toDouble().clamp(1000, 20000),
                      label: '${settings.scrollbackLines}',
                      onChanged: (v) => scope.settings.update(
                        settings.copyWith(scrollbackLines: v.round()),
                      ),
                    ),
                    const Text('下次连接生效', style: TextStyle(fontSize: 11)),
                  ],
                ),
                trailing: Text('${settings.scrollbackLines}'),
              ),
              _header(context, '连接'),
              ListTile(
                title: const Text('保活间隔'),
                subtitle: Slider(
                  min: 0,
                  max: 120,
                  divisions: 12,
                  value: settings.keepAliveSeconds.toDouble(),
                  label: settings.keepAliveSeconds == 0
                      ? '已关闭'
                      : '${settings.keepAliveSeconds} 秒',
                  onChanged: (v) => scope.settings.update(
                    settings.copyWith(keepAliveSeconds: v.round()),
                  ),
                ),
                trailing: Text(
                  settings.keepAliveSeconds == 0 ? '已关闭' : '${settings.keepAliveSeconds}s',
                ),
              ),
              ListTile(
                title: const Text('连接超时'),
                subtitle: Slider(
                  min: 5,
                  max: 60,
                  divisions: 11,
                  value: settings.connectTimeoutSeconds.toDouble().clamp(5, 60),
                  label: '${settings.connectTimeoutSeconds} 秒',
                  onChanged: (v) => scope.settings.update(
                    settings.copyWith(connectTimeoutSeconds: v.round()),
                  ),
                ),
                trailing: Text('${settings.connectTimeoutSeconds}s'),
              ),
              SwitchListTile(
                title: const Text('默认记住密码'),
                value: settings.rememberPasswordsByDefault,
                onChanged: (v) => scope.settings.update(
                  settings.copyWith(rememberPasswordsByDefault: v),
                ),
              ),
              SwitchListTile(
                title: const Text('连接时保持屏幕常亮'),
                value: settings.keepScreenOn,
                onChanged: (v) => scope.settings.update(
                  settings.copyWith(keepScreenOn: v),
                ),
              ),
              _header(context, '按键映射'),
              const ListTile(
                title: Text('按键映射'),
                subtitle: Text('仅 Android 生效：把音量键等映射为 Ctrl、方向键等'),
              ),
              for (final m in settings.keyMappings)
                ListTile(
                  title: Text(
                    '${keyMappingSourceLabel(m.source)} → ${keyMappingActionLabel(m.action)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: '删除',
                    onPressed: () => _removeMapping(context, m),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('添加映射'),
                onTap: () => _addMapping(context),
              ),
              _header(context, '数据'),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('导出配置'),
                onTap: () => exportBackup(context),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('导入配置'),
                onTap: () => importBackup(context),
              ),
              ListTile(
                leading: const Icon(Icons.key_off_outlined),
                title: const Text('清除所有主机密钥'),
                onTap: () => _clearKnownHosts(context),
              ),
              ListTile(
                leading: const Icon(Icons.password_outlined),
                title: const Text('清除所有已保存密码'),
                onTap: () => _clearPasswords(context),
              ),
              _header(context, '关于'),
              const ListTile(
                title: Text('Termora'),
                subtitle: Text('版本 $kAppVersion'),
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('查看开源许可'),
                onTap: () => showLicensePage(context: context, applicationName: 'Termora'),
              ),
              const SizedBox(height: Space.x6),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x5, Space.x4, Space.x2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _swatch(TerminalTheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final color in [
          theme.red,
          theme.green,
          theme.yellow,
          theme.blue,
        ])
          Container(width: 12, height: 12, color: color),
      ],
    );
  }

  Future<void> _removeMapping(BuildContext context, KeyMapping mapping) async {
    final scope = ServicesScope.of(context);
    final next = scope.settings.settings.keyMappings
        .where((m) => m != mapping)
        .toList();
    await scope.settings.update(scope.settings.settings.copyWith(keyMappings: next));
  }

  Future<void> _addMapping(BuildContext context) async {
    final scope = ServicesScope.of(context);
    final current = scope.settings.settings.keyMappings;
    var source = kKeyMappingSources.first.id;
    var action = kKeyMappingActions.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加映射'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: source,
                decoration: const InputDecoration(labelText: '按键'),
                items: [
                  for (final s in kKeyMappingSources)
                    DropdownMenuItem(value: s.id, child: Text(s.label)),
                ],
                onChanged: (v) => setDialogState(() => source = v ?? source),
              ),
              const SizedBox(height: Space.x3),
              DropdownButtonFormField<String>(
                initialValue: action,
                decoration: const InputDecoration(labelText: '动作'),
                items: [
                  for (final a in kKeyMappingActions)
                    DropdownMenuItem(value: a.id, child: Text(a.label)),
                ],
                onChanged: (v) => setDialogState(() => action = v ?? action),
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
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final next = [
      for (final m in current)
        if (m.source != source) m,
      KeyMapping(source: source, action: action),
    ];
    await scope.settings.update(scope.settings.settings.copyWith(keyMappings: next));
  }

  Future<void> _clearKnownHosts(BuildContext context) async {
    final scope = ServicesScope.of(context);
    final count = scope.knownHosts.entries.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有主机密钥'),
        content: Text('将删除已保存的 $count 个主机密钥，下次连接需要重新确认。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final removed = await scope.knownHosts.clearAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已清除 $removed 个主机密钥')),
    );
  }

  Future<void> _clearPasswords(BuildContext context) async {
    final scope = ServicesScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有已保存密码'),
        content: const Text('将删除所有已保存的登录密码与私钥口令，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    for (final server in scope.servers.servers) {
      await scope.secretStore.delete('password:${server.id}');
      await scope.secretStore.delete('passphrase:${server.id}');
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已清除所有已保存密码')),
    );
  }
}
