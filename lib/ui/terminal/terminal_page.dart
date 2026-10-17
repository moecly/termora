import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../data/settings_repository.dart';
import '../../design/tokens.dart';
import '../../session/session_status.dart';
import '../../session/terminal_session.dart';
import '../../terminal/terminal_themes.dart';
import '../servers/server_edit_page.dart';
import 'helper_key_bar.dart';
import 'terminal_viewport.dart';

/// Full-screen terminal page (mobile by default; also reachable on desktop).
class TerminalPage extends StatelessWidget {
  const TerminalPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.manager, scope.settings]),
      builder: (context, _) {
        final session = scope.manager.sessionById(sessionId);
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('会话已关闭')),
          );
        }
        return _TerminalScaffold(session: session, settings: scope.settings.settings);
      },
    );
  }
}

class _TerminalScaffold extends StatelessWidget {
  const _TerminalScaffold({required this.session, required this.settings});

  final TerminalSession session;
  final AppSettings settings;

  Color _statusColor(BuildContext context, SessionStatus status) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (status) {
      SessionStatus.connecting => AppColors.warning,
      SessionStatus.connected => AppColors.success,
      SessionStatus.disconnected =>
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      SessionStatus.failed => AppColors.danger,
    };
  }

  String _statusText() {
    return switch (session.status) {
      SessionStatus.connecting => '正在连接…',
      SessionStatus.connected =>
        '已连接 · ${session.remoteTitle ?? session.server.host}',
      SessionStatus.disconnected => session.errorMessage ?? '连接已断开',
      SessionStatus.failed => session.errorMessage ?? '连接失败',
    };
  }

  void _toggleKeyboard() {
    if (session.focusNode.hasFocus) {
      session.focusNode.unfocus();
    } else {
      session.focusNode.requestFocus();
    }
  }

  Future<void> _showSessionSwitcher(BuildContext context) async {
    final manager = ServicesScope.of(context).manager;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in manager.sessions)
              ListTile(
                leading: Icon(
                  s.id == manager.activeSessionId
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                ),
                title: Text(s.server.name),
                subtitle: Text('${s.server.username}@${s.server.host}:${s.server.port}'),
                onTap: () {
                  manager.activate(s.id);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showServerInfo(BuildContext context) async {
    final s = session.server;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('主机', '${s.host}:${s.port}'),
            _infoRow('用户名', s.username),
            _infoRow('认证方式', s.authMethod == AuthMethod.password ? '密码' : '私钥'),
            if (session.remoteVersion != null)
              _infoRow('远端版本', session.remoteVersion!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  Future<void> _showThemePicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            RadioGroup<String>(
              groupValue: settings.terminalThemeId,
              onChanged: (value) {
                if (value != null) {
                  ServicesScope.of(context)
                      .settings
                      .update(settings.copyWith(terminalThemeId: value));
                }
                Navigator.of(context).pop();
              },
              child: Column(
                children: [
                  for (final entry in kTerminalThemes.keys)
                    RadioListTile<String>(
                      value: entry,
                      title: Text(kTerminalThemeLabels[entry] ?? entry),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeFontSize(BuildContext context, double delta) {
    final scope = ServicesScope.of(context);
    final next = (settings.terminalFontSize + delta).clamp(10.0, 22.0);
    scope.settings.update(settings.copyWith(terminalFontSize: next));
  }

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    final manager = scope.manager;
    final theme = kTerminalThemes[settings.terminalThemeId]!;

    return Scaffold(
      backgroundColor: theme.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              session.server.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Text(
              _statusText(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: _statusColor(context, session.status),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_outlined),
            onPressed: _toggleKeyboard,
          ),
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            onPressed: () => _showSessionSwitcher(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'reconnect':
                  final size = session.terminal.viewWidth;
                  await session.reconnect(
                    width: size > 0 ? size : 80,
                    height: session.terminal.viewHeight > 0
                        ? session.terminal.viewHeight
                        : 24,
                  );
                case 'disconnect':
                  await session.disconnect();
                case 'close':
                  await manager.closeSession(session.id);
                  if (context.mounted) Navigator.of(context).pop();
                case 'fontUp':
                  _changeFontSize(context, 1);
                case 'fontDown':
                  _changeFontSize(context, -1);
                case 'theme':
                  await _showThemePicker(context);
                case 'edit':
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ServerEditPage(server: session.server),
                    ),
                  );
                case 'info':
                  await _showServerInfo(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'reconnect', child: Text('重新连接')),
              PopupMenuItem(value: 'disconnect', child: Text('断开连接')),
              PopupMenuItem(value: 'close', child: Text('关闭会话')),
              PopupMenuItem(value: 'fontUp', child: Text('增大字号')),
              PopupMenuItem(value: 'fontDown', child: Text('减小字号')),
              PopupMenuItem(value: 'theme', child: Text('终端配色')),
              PopupMenuItem(value: 'edit', child: Text('编辑服务器')),
              PopupMenuItem(value: 'info', child: Text('服务器信息')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TerminalViewport(session: session, settings: settings),
          ),
          _SelectionBar(session: session),
          HelperKeyBar(session: session),
        ],
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.session});

  final TerminalSession session;

  void _invoke(Intent intent) {
    final context = session.builderKey.currentContext;
    if (context == null) return;
    Actions.invoke(context, intent);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session.terminalController,
      builder: (context, _) {
        final hasSelection = session.terminalController.selection != null;
        return AnimatedSize(
          duration: Motion.fast,
          curve: Motion.curve,
          child: hasSelection
              ? SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      const SizedBox(width: Space.x2),
                      TextButton(
                        onPressed: () {
                          _invoke(CopySelectionTextIntent.copy);
                          session.terminalController.clearSelection();
                        },
                        child: const Text('复制'),
                      ),
                      TextButton(
                        onPressed: () => _invoke(
                          const SelectAllTextIntent(SelectionChangedCause.toolbar),
                        ),
                        child: const Text('全选'),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: session.terminalController.clearSelection,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        );
      },
    );
  }
}
