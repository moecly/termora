import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app.dart';
import '../../design/motion.dart';
import '../../design/palette.dart';
import '../../design/tokens.dart';
import '../common/backup_actions.dart';
import '../servers/server_edit_page.dart';
import '../servers/server_tile.dart';
import '../settings/settings_page.dart';

/// Opens the command palette (desktop).
Future<void> showCommandPalette(
  BuildContext context, {
  VoidCallback? onOpenThemeInspector,
}) {
  final p = AppPalette.of(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '命令面板',
    barrierColor: p.scrim,
    transitionDuration: AppMotion.scale(context, Motion.overlay),
    pageBuilder: (context, animation, secondaryAnimation) => CommandPalette(
      onOpenThemeInspector: onOpenThemeInspector,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      if (AppMotion.reduced(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Motion.emphasized,
        reverseCurve: Motion.emphasizedAccel,
      );
      return FadeTransition(
        opacity: curved,
        child: Transform.translate(
          offset: Offset(0, -12 * (1 - curved.value)),
          child: Transform.scale(
            scale: 0.97 + 0.03 * curved.value,
            child: child,
          ),
        ),
      );
    },
  );
}

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key, this.onOpenThemeInspector});

  final VoidCallback? onOpenThemeInspector;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  int _selected = 0;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    final p = AppPalette.of(context);
    final brightness = Theme.of(context).brightness;

    final servers = scope.servers.servers
        .where((s) => _matches(_query, s.name, s.host, s.username))
        .take(8)
        .toList();

    final entries = <_Entry>[
      for (final server in servers)
        _Entry(
          group: '服务器',
          icon: Icons.dns_outlined,
          label: server.name,
          sub: '${server.username}@${server.host}',
          run: () => openSession(context, server),
        ),
      for (final session in scope.manager.sessions)
        if (_matches(_query, session.server.name, session.server.host, '会话'))
          _Entry(
            group: '会话',
            icon: Icons.terminal,
            label: session.server.name,
            sub: '切换会话',
            run: () => scope.manager.activate(session.id),
          ),
      for (final session in scope.manager.sessions)
        if (_matches(_query, session.server.name, session.server.host, '关闭会话'))
          _Entry(
            group: '会话',
            icon: Icons.close,
            label: '关闭会话',
            sub: session.server.name,
            run: () => scope.manager.closeSession(session.id),
          ),
      if (_matches(_query, '新增服务器', 'new server'))
        _Entry(
          group: '操作',
          icon: Icons.add,
          label: '新增服务器',
          sub: '',
          run: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ServerEditPage()),
          ),
        ),
      if (_matches(_query, '设置', 'settings'))
        _Entry(
          group: '操作',
          icon: Icons.settings_outlined,
          label: '设置',
          sub: '',
          run: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
          ),
        ),
      if (_matches(_query, '导入', 'import'))
        _Entry(
          group: '操作',
          icon: Icons.file_upload_outlined,
          label: '导入',
          sub: '',
          run: () => importBackup(context),
        ),
      if (_matches(_query, '导出', 'export'))
        _Entry(
          group: '操作',
          icon: Icons.file_download_outlined,
          label: '导出',
          sub: '',
          run: () => exportBackup(context),
        ),
      if (_matches(_query, '切换终端配色', 'theme'))
        _Entry(
          group: '操作',
          icon: Icons.palette_outlined,
          label: '切换终端配色',
          sub: '',
          run: () {
            final cb = widget.onOpenThemeInspector;
            if (cb != null) {
              cb();
            } else {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
              );
            }
          },
        ),
    ];

    final selected = entries.isEmpty ? 0 : _selected.clamp(0, entries.length - 1);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 96),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                setState(() => _selected =
                    entries.isEmpty ? 0 : (selected + 1) % entries.length);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                setState(() => _selected = entries.isEmpty
                    ? 0
                    : (selected - 1 + entries.length) % entries.length);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.enter) {
                if (entries.isNotEmpty) {
                  Navigator.of(context).pop();
                  entries[selected].run();
                }
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.of(context).pop();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Material(
              color: p.surfaceHigh,
              borderRadius: BorderRadius.circular(Radii.xl),
              clipBehavior: Clip.antiAlias,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: AppShadows.of(brightness, 4),
                  borderRadius: BorderRadius.circular(Radii.xl),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '搜索服务器、会话或命令',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                      onChanged: (v) => setState(() {
                        _query = v.trim();
                        _selected = 0;
                      }),
                    ),
                    Divider(height: 1, color: p.border),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: entries.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(Space.x6),
                              child: Text('没有匹配'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: entries.length,
                              itemBuilder: (context, i) => _EntryRow(
                                entry: entries[i],
                                selected: i == selected,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  entries[i].run();
                                },
                              ),
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
  }

  bool _matches(String query, String a, [String b = '', String c = '']) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return a.toLowerCase().contains(q) ||
        b.toLowerCase().contains(q) ||
        c.toLowerCase().contains(q);
  }
}

class _Entry {
  const _Entry({
    required this.group,
    required this.icon,
    required this.label,
    required this.sub,
    required this.run,
  });

  final String group;
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback run;
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _Entry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.control,
        color: selected ? p.accentSoft : Colors.transparent,
        child: Row(
          children: [
            AnimatedContainer(
              duration: Motion.control,
              width: 2,
              height: 44,
              color: selected ? p.accent : Colors.transparent,
            ),
            const SizedBox(width: Space.x3),
            Icon(entry.icon, size: 18, color: p.textSecondary),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Text(entry.label, style: const TextStyle(fontSize: 13)),
            ),
            if (entry.sub.isNotEmpty)
              Text(
                entry.sub,
                style: TextStyle(fontSize: 11, color: p.textTertiary),
              ),
            const SizedBox(width: Space.x4),
          ],
        ),
      ),
    );
  }
}
