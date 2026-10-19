import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app.dart';
import '../../data/models.dart';
import '../../data/settings_repository.dart';
import '../../design/motion.dart';
import '../../design/overlays.dart';
import '../../design/tokens.dart';
import '../../design/widgets/link_indicator.dart';
import '../../design/widgets/server_avatar.dart';
import '../../design/widgets/theme_swatch.dart';
import '../../session/session_status.dart';
import '../../session/terminal_session.dart';
import '../../terminal/terminal_style.dart';
import '../../terminal/terminal_themes.dart';
import '../servers/server_edit_page.dart';
import 'connect_sequence.dart';
import 'key_deck.dart';
import 'session_banner.dart';
import 'terminal_viewport.dart';

/// Full-screen terminal page (mobile by default; also reachable on desktop).
class TerminalPage extends StatelessWidget {
  const TerminalPage({super.key, required this.sessionId, this.heroTag});

  final String sessionId;

  /// Hero tag of the avatar this page was opened from. Falls back to the
  /// server-scoped tag (used by the server list) when unset.
  final String? heroTag;

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
        return _TerminalScaffold(
          session: session,
          settings: scope.settings.settings,
          heroTag: heroTag,
        );
      },
    );
  }
}

class _TerminalScaffold extends StatefulWidget {
  const _TerminalScaffold({
    required this.session,
    required this.settings,
    this.heroTag,
  });

  final TerminalSession session;
  final AppSettings settings;
  final String? heroTag;

  @override
  State<_TerminalScaffold> createState() => _TerminalScaffoldState();
}

class _TerminalScaffoldState extends State<_TerminalScaffold>
    with SingleTickerProviderStateMixin {
  bool _fullscreen = false;

  /// Idle timer for the immersive chrome: when it completes (3.5s of no
  /// input) the app bar and key deck hide to give the terminal full space.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  );

  TerminalSession get session => widget.session;
  AppSettings get settings => widget.settings;

  bool get _chromeVisible => _idle.status != AnimationStatus.completed;
  bool get _hideChrome => _fullscreen || !_chromeVisible;

  @override
  void initState() {
    super.initState();
    _idle.addStatusListener(_onIdleStatus);
    session.addListener(_onSessionChanged);
    _ping();
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    _idle.dispose();
    super.dispose();
  }

  void _onIdleStatus(AnimationStatus status) {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_TerminalScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!settings.terminalImmersiveChrome) {
      if (_idle.isAnimating) _idle.stop();
      if (_idle.value != 0) {
        _idle.value = 0;
        setState(() {});
      }
    }
  }

  void _onSessionChanged() => _ping();

  /// Restarts the idle countdown; ignored when immersive mode is off.
  void _ping() {
    if (!settings.terminalImmersiveChrome) {
      if (_idle.isAnimating) _idle.stop();
      return;
    }
    _idle.forward(from: 0);
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
    await showAppSheet<void>(
      context,
      builder: (context) => ListView(
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
    );
  }

  Future<void> _showServerInfo(BuildContext context) async {
    final s = session.server;
    await showAppDialog<void>(
      context,
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
    await showAppSheet<void>(
      context,
      builder: (context) => ListView(
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
                    secondary: TerminalThemeSwatch(
                      theme: kTerminalThemes[entry]!,
                      selected: settings.terminalThemeId == entry,
                    ),
                    title: Text(kTerminalThemeLabels[entry] ?? entry),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changeFontSize(BuildContext context, double delta) {
    final scope = ServicesScope.of(context);
    final next = (settings.terminalFontSize + delta)
        .clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
    scope.settings.update(settings.copyWith(terminalFontSize: next));
  }

  @override
  Widget build(BuildContext context) {
    final scope = ServicesScope.of(context);
    final manager = scope.manager;
    final theme = kTerminalThemes[settings.terminalThemeId]!;
    final lightBackground = theme.background.computeLuminance() > 0.5;

    final appBar = AppBar(
      backgroundColor: theme.background,
      foregroundColor: theme.foreground,
      systemOverlayStyle:
          lightBackground ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      leading: IconButton(
        style: _appBarIconStyle(theme.foreground),
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          ServerAvatar(
            seed: session.server.name,
            size: 28,
            heroTag: widget.heroTag ?? serverHeroTag(session.server.id),
          ),
          const SizedBox(width: Space.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.server.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.foreground,
                  ),
                ),
                AnimatedSwitcher(
                  duration: Motion.tab,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Row(
                    key: ValueKey(_statusText()),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinkIndicator(status: session.status, size: 8),
                      const SizedBox(width: Space.x1),
                      Flexible(
                        child: Text(
                          _statusText(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: terminalStatusColor(session.status, theme),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          style: _appBarIconStyle(theme.foreground),
          icon: Icon(_fullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
          tooltip: _fullscreen ? '退出全屏' : '全屏',
          onPressed: () => setState(() => _fullscreen = !_fullscreen),
        ),
        IconButton(
          style: _appBarIconStyle(theme.foreground),
          icon: const Icon(Icons.keyboard_outlined),
          onPressed: _toggleKeyboard,
        ),
        IconButton(
          style: _appBarIconStyle(theme.foreground),
          icon: const Icon(Icons.layers_outlined),
          onPressed: () => _showSessionSwitcher(context),
        ),
        PopupMenuButton<String>(
          iconColor: theme.foreground,
          popUpAnimationStyle: AppMotion.style(
            context,
            duration: Motion.overlay,
            reverseDuration: Motion.press,
          ),
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
    );

    final terminalStack = Stack(
      children: [
        Positioned.fill(
          child: TerminalViewport(session: session, settings: settings),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: AppMotion.scale(context, Motion.panel),
              child: session.status == SessionStatus.connecting
                  ? ColoredBox(
                      key: const ValueKey('connecting'),
                      color: theme.background,
                      child: ConnectSequence(session: session),
                    )
                  : const SizedBox.shrink(key: ValueKey('live')),
            ),
          ),
        ),
        if (session.status == SessionStatus.failed ||
            session.status == SessionStatus.disconnected)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SessionBanner(session: session),
          ),
      ],
    );

    final body = AnimatedSize(
      duration: AppMotion.scale(context, Motion.panel),
      curve: Motion.emphasized,
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          Expanded(child: terminalStack),
          _SelectionBar(session: session),
          KeyDeck(session: session, collapsed: _hideChrome),
        ],
      ),
    );

    final hiddenControls = Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.x2),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: AppMotion.scale(context, Motion.panel),
            curve: Motion.emphasized,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
            ),
            child: Row(
              children: [
                if (_fullscreen)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.x2),
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                        tooltip: '退出全屏',
                        onPressed: () => setState(() => _fullscreen = false),
                      ),
                    ),
                  ),
                Material(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: '返回',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: !_fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _fullscreen = false);
      },
      child: Scaffold(
        backgroundColor: theme.background,
        resizeToAvoidBottomInset: true,
        appBar: _hideChrome ? null : appBar,
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _ping(),
          onPointerMove: (_) => _ping(),
          onPointerSignal: (_) => _ping(),
          child: Focus(
            onKeyEvent: (_, _) {
              _ping();
              return KeyEventResult.ignored;
            },
            child: Stack(
              children: [
                body,
                if (_hideChrome) hiddenControls,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon styling for the terminal AppBar. The app Bar sits on the terminal
/// theme's background, so the app theme's icon colors (tuned for the app
/// surface) would be unreadable here — pin them to the terminal foreground.
ButtonStyle _appBarIconStyle(Color foreground) => IconButton.styleFrom(
  foregroundColor: foreground,
  disabledForegroundColor: foreground.withValues(alpha: 0.38),
  hoverColor: foreground.withValues(alpha: 0.10),
  highlightColor: foreground.withValues(alpha: 0.16),
);

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
          duration: Motion.panel,
          curve: Motion.emphasized,
          child: hasSelection
              ? SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      const SizedBox(width: Space.x2),
                      _SlideIn(
                        child: TextButton(
                          onPressed: () {
                            _invoke(CopySelectionTextIntent.copy);
                            session.terminalController.clearSelection();
                          },
                          child: const Text('复制'),
                        ),
                      ),
                      _SlideIn(
                        child: TextButton(
                          onPressed: () => _invoke(
                            const PasteTextIntent(SelectionChangedCause.toolbar),
                          ),
                          child: const Text('粘贴'),
                        ),
                      ),
                      _SlideIn(
                        child: TextButton(
                          onPressed: () => _invoke(
                            const SelectAllTextIntent(SelectionChangedCause.toolbar),
                          ),
                          child: const Text('全选'),
                        ),
                      ),
                      const Spacer(),
                      _SlideIn(
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: session.terminalController.clearSelection,
                        ),
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

/// Fades and slides its child in from below on first build.
class _SlideIn extends StatelessWidget {
  const _SlideIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.scale(context, Motion.tab),
      curve: Motion.emphasized,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: FractionalTranslation(
          translation: Offset(0, 0.4 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
