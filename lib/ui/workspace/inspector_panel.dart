import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm2/xterm.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../design/motion.dart';
import '../../design/palette.dart';
import '../../design/tokens.dart';
import '../../design/widgets/mask_reveal.dart';
import '../../design/widgets/pressable.dart';
import '../../design/widgets/theme_swatch.dart';
import '../../session/terminal_session.dart';
import '../../terminal/terminal_themes.dart';
import '../servers/server_edit_page.dart';

/// What the inspector panel is currently showing.
sealed class InspectorContent {
  const InspectorContent();
}

final class SearchResultsInspector extends InspectorContent {
  const SearchResultsInspector({required this.session, required this.matches});

  final TerminalSession session;
  final List<TerminalSearchMatch> matches;
}

final class ServerInspector extends InspectorContent {
  const ServerInspector({required this.session});

  final TerminalSession session;
}

final class TerminalThemeInspector extends InspectorContent {
  const TerminalThemeInspector();
}

/// The right-hand inspector panel: search results, server info or theme picker.
class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key, required this.content, required this.onClose});

  final InspectorContent? content;
  final VoidCallback onClose;

  static const double width = 320;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(left: BorderSide(color: p.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.only(left: Space.x4, right: Space.x1),
              child: Row(
                children: [
                  Text(
                    _title(content),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '关闭',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: p.border),
          Expanded(
            child: MaskReveal(
              axis: Axis.horizontal,
              duration: Motion.reveal,
              open: true,
              child: AnimatedSwitcher(
                duration: Motion.overlay,
                child: KeyedSubtree(
                  key: ValueKey(content.runtimeType),
                  child: _body(context, content),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _title(InspectorContent? content) => switch (content) {
        SearchResultsInspector() => '搜索结果',
        ServerInspector() => '服务器信息',
        TerminalThemeInspector() => '终端配色',
        null => '',
      };

  Widget _body(BuildContext context, InspectorContent? content) {
    return switch (content) {
      SearchResultsInspector(:final session, :final matches) =>
        _SearchResults(session: session, matches: matches),
      ServerInspector(:final session) => _ServerInfo(session: session),
      TerminalThemeInspector() => const _ThemePicker(),
      null => const SizedBox.shrink(),
    };
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.session, required this.matches});

  final TerminalSession session;
  final List<TerminalSearchMatch> matches;

  void _jump(int index) {
    session.terminalController.setCurrentSearchHighlight(index);
    final pos = session.scrollController.positions.isEmpty
        ? null
        : session.scrollController.position;
    if (pos == null || !pos.hasContentDimensions) return;
    final lines = session.terminal.buffer.height;
    final viewLines = session.terminal.viewHeight;
    if (lines > viewLines && pos.maxScrollExtent > 0) {
      final lineHeight = pos.maxScrollExtent / (lines - viewLines);
      final y = (matches[index].range.begin.y - viewLines ~/ 3)
          .clamp(0, lines - viewLines);
      session.scrollController.animateTo(
        (y * lineHeight).clamp(pos.minScrollExtent, pos.maxScrollExtent),
        duration: Motion.panel,
        curve: Motion.emphasized,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    if (matches.isEmpty) {
      return const Center(child: Text('没有匹配'));
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, i) {
        final match = matches[i];
        return HoverSurface(
          baseColor: Colors.transparent,
          hoverColor: p.hoverOverlay,
          border: const BorderSide(color: Colors.transparent),
          hoverBorder: const BorderSide(color: Colors.transparent),
          onTap: () => _jump(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.x4,
              vertical: Space.x2,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '${match.range.begin.y + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: p.textTertiary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServerInfo extends StatelessWidget {
  const _ServerInfo({required this.session});

  final TerminalSession session;

  @override
  Widget build(BuildContext context) {
    final s = session.server;
    return ListView(
      padding: const EdgeInsets.all(Space.x4),
      children: [
        _row('主机', '${s.host}:${s.port}'),
        _row('用户名', s.username),
        _row('认证方式', s.authMethod == AuthMethod.password ? '密码' : '私钥'),
        if (session.remoteVersion != null) _row('远端版本', session.remoteVersion!),
        const SizedBox(height: Space.x4),
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ServerEditPage(server: s),
            ),
          ),
          child: const Text('编辑服务器'),
        ),
        const SizedBox(height: Space.x2),
        OutlinedButton(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: '${s.username}@${s.host}:${s.port}'),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制地址')),
              );
            }
          },
          child: const Text('复制地址'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
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
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    final settings = scope.settings.settings;
    return ListView(
      padding: const EdgeInsets.all(Space.x2),
      children: [
        for (final entry in kTerminalThemes.entries)
          ListTile(
            leading: TerminalThemeSwatch(
              theme: entry.value,
              selected: settings.terminalThemeId == entry.key,
            ),
            title: Text(kTerminalThemeLabels[entry.key] ?? entry.key),
            onTap: () => scope.settings.update(
              settings.copyWith(terminalThemeId: entry.key),
            ),
          ),
      ],
    );
  }
}
