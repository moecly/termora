import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import '../../app/app.dart';
import '../../data/key_mapping.dart';
import '../../data/settings_repository.dart';
import '../../design/overlays.dart';
import '../../design/palette.dart';
import '../../design/tokens.dart';
import '../../design/widgets/animated_diff_list.dart';
import '../../design/widgets/enter_transition.dart';
import '../../design/widgets/section_header.dart';
import '../../design/widgets/theme_swatch.dart';
import '../../terminal/terminal_themes.dart';
import '../common/backup_actions.dart';

const String kAppVersion = '1.0.2+2';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Map<String, KeyMapping> _mappingCache = {};

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    return ListenableBuilder(
      listenable: scope.settings,
      builder: (context, _) {
        final settings = scope.settings.settings;
        for (final m in settings.keyMappings) {
          _mappingCache['map:${m.source}'] = m;
        }
        final mappingKeys = [for (final m in settings.keyMappings) 'map:${m.source}'];

        return Scaffold(
          appBar: AppBar(title: const Text('设置')),
          body: ListView(
            padding: const EdgeInsets.only(bottom: Space.x6),
            children: [
              _card(
                index: 0,
                title: '外观',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                    child: SegmentedButton<ThemeSetting>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeSetting.system,
                          icon: Icon(Icons.brightness_auto),
                          label: Text('跟随系统'),
                        ),
                        ButtonSegment(
                          value: ThemeSetting.light,
                          icon: Icon(Icons.light_mode),
                          label: Text('浅色'),
                        ),
                        ButtonSegment(
                          value: ThemeSetting.dark,
                          icon: Icon(Icons.dark_mode),
                          label: Text('深色'),
                        ),
                      ],
                      selected: {settings.theme},
                      onSelectionChanged: (s) =>
                          scope.settings.update(settings.copyWith(theme: s.first)),
                    ),
                  ),
                ],
              ),
              _card(
                index: 1,
                title: '终端',
                children: [
                  ListTile(
                    title: const Text('字号'),
                    subtitle: Slider(
                      min: kTerminalFontSizeMin,
                      max: kTerminalFontSizeMax,
                      divisions: 20,
                      value: settings.terminalFontSize,
                      label: '${settings.terminalFontSize.round()} pt',
                      onChanged: (v) => scope.settings
                          .update(settings.copyWith(terminalFontSize: v)),
                    ),
                    trailing: Text(
                      '${settings.terminalFontSize.round()} pt',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('沉浸模式（自动隐藏终端工具栏）'),
                    value: settings.terminalImmersiveChrome,
                    onChanged: (v) => scope.settings.update(
                      settings.copyWith(terminalImmersiveChrome: v),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, Space.x2),
                    child: Text('配色'),
                  ),
                  RadioGroup<String>(
                    groupValue: settings.terminalThemeId,
                    onChanged: (value) {
                      if (value != null) {
                        scope.settings
                            .update(settings.copyWith(terminalThemeId: value));
                      }
                    },
                    child: Column(
                      children: [
                        for (final entry in kTerminalThemes.entries)
                          RadioListTile<String>(
                            value: entry.key,
                            title: Text(kTerminalThemeLabels[entry.key] ?? entry.key),
                            secondary: _swatch(
                              entry.value,
                              selected: settings.terminalThemeId == entry.key,
                            ),
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
                ],
              ),
              _card(
                index: 2,
                title: '连接',
                children: [
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
                      settings.keepAliveSeconds == 0
                          ? '已关闭'
                          : '${settings.keepAliveSeconds}s',
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
                ],
              ),
              _card(
                index: 3,
                title: '按键映射',
                children: [
                  const ListTile(
                    title: Text('按键映射'),
                    subtitle: Text('仅 Android 生效：把音量键等映射为 Ctrl、方向键等'),
                  ),
                  AnimatedDiffList(
                    keys: mappingKeys,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index, key, animation) =>
                        _mappingTile(_mappingCache[key]!),
                    removedBuilder: (context, key, animation) =>
                        _mappingCache[key] != null
                            ? _mappingTile(_mappingCache[key]!)
                            : const SizedBox.shrink(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('添加映射'),
                    onTap: () => _addMapping(context),
                  ),
                ],
              ),
              _card(
                index: 4,
                title: '数据',
                children: [
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
                    leading: const Icon(Icons.key_off_outlined, color: AppColors.danger),
                    title: const Text('清除所有主机密钥'),
                    onTap: () => _clearKnownHosts(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.password_outlined, color: AppColors.danger),
                    title: const Text('清除所有已保存密码'),
                    onTap: () => _clearPasswords(context),
                  ),
                ],
              ),
              _card(
                index: 5,
                title: '关于',
                children: [
                  const ListTile(
                    title: Text('Termora'),
                    subtitle: Text('版本 $kAppVersion'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('查看开源许可'),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Termora',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card({
    required int index,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final p = AppPalette.of(context);
    return EnterTransition(
      index: index,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x2),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: p.border),
          boxShadow: AppShadows.of(theme.brightness, 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: title, dense: true),
            ...children,
            const SizedBox(height: Space.x2),
          ],
        ),
      ),
    );
  }

  Widget _mappingTile(KeyMapping mapping) {
    return ListTile(
      title: Text(
        '${keyMappingSourceLabel(mapping.source)} → ${keyMappingActionLabel(mapping.action)}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 18),
        tooltip: '删除',
        onPressed: () => _removeMapping(context, mapping),
      ),
    );
  }

  Widget _swatch(TerminalTheme theme, {required bool selected}) {
    return TerminalThemeSwatch(theme: theme, selected: selected);
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
    final confirmed = await showAppDialog<bool>(
      context,
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
    final confirmed = await showAppDialog<bool>(
      context,
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
    final confirmed = await showAppDialog<bool>(
      context,
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
