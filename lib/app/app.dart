import 'dart:async';

import 'package:flutter/material.dart';

import '../data/known_hosts_repository.dart';
import '../data/models.dart';
import '../data/secret_store.dart';
import '../data/server_repository.dart';
import '../data/settings_repository.dart';
import '../design/app_theme.dart';
import '../design/motion.dart';
import '../session/hardware_key_service.dart';
import '../session/session_manager.dart';
import '../ssh/connection_factory.dart';
import '../ssh/host_key_verifier.dart';
import '../ssh/ssh_connection.dart';
import '../ui/common/prompts.dart';
import 'root_shell.dart';

/// Exposes the app's services to the widget tree. Only [SessionManager] changes
/// trigger rebuilds; the repositories are final and never swap.
class ServicesScope extends InheritedNotifier<SessionManager> {
  const ServicesScope({
    super.key,
    required SessionManager manager,
    required this.secretStore,
    required this.servers,
    required this.settings,
    required this.knownHosts,
    required this.navigatorKey,
    required this.prompts,
    required this.hostKeyVerifier,
    required super.child,
  }) : super(notifier: manager);

  final SecretStore secretStore;
  final ServerRepository servers;
  final SettingsRepository settings;
  final KnownHostsRepository knownHosts;
  final GlobalKey<NavigatorState> navigatorKey;
  final PromptQueue prompts;
  final HostKeyVerifier hostKeyVerifier;

  SessionManager get manager => notifier!;

  static ServicesScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ServicesScope>();
    assert(scope != null, 'ServicesScope not found in the widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(InheritedNotifier<SessionManager> oldWidget) => false;
}

class TermoraApp extends StatefulWidget {
  const TermoraApp({
    super.key,
    required this.secretStore,
    required this.servers,
    required this.knownHosts,
    required this.settings,
  });

  final SecretStore secretStore;
  final ServerRepository servers;
  final KnownHostsRepository knownHosts;
  final SettingsRepository settings;

  @override
  State<TermoraApp> createState() => _TermoraAppState();
}

class _TermoraAppState extends State<TermoraApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final PromptQueue _prompts = PromptQueue();

  late final HostKeyVerifier _hostKeyVerifier = HostKeyVerifier(
    knownHosts: widget.knownHosts,
    navigatorKey: _navigatorKey,
    queue: _prompts,
  );

  Future<SshConnection> _connect({
    required ServerConfig server,
    required int width,
    required int height,
  }) {
    return defaultSshConnector(
      server: server,
      width: width,
      height: height,
      secretStore: widget.secretStore,
      verifier: _hostKeyVerifier,
      navigatorKey: _navigatorKey,
      settings: widget.settings.settings,
      prompts: _prompts,
    );
  }

  late final SessionManager _sessionManager = SessionManager(
    servers: widget.servers,
    settings: widget.settings,
    connector: _connect,
  );

  late final HardwareKeyService _hardwareKeys = HardwareKeyService(
    manager: _sessionManager,
    settings: widget.settings,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_hardwareKeys.init());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hardwareKeys.dispose();
    _sessionManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        _sessionManager.disconnectAll();
      case AppLifecycleState.resumed:
        for (final session in _sessionManager.sessions) {
          session.refreshLiveness();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        break;
    }
  }

  ThemeMode _themeMode(ThemeSetting setting) {
    return switch (setting) {
      ThemeSetting.system => ThemeMode.system,
      ThemeSetting.light => ThemeMode.light,
      ThemeSetting.dark => ThemeMode.dark,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) {
        return ServicesScope(
          manager: _sessionManager,
          secretStore: widget.secretStore,
          servers: widget.servers,
          settings: widget.settings,
          knownHosts: widget.knownHosts,
          navigatorKey: _navigatorKey,
          prompts: _prompts,
          hostKeyVerifier: _hostKeyVerifier,
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Termora',
            debugShowCheckedModeBanner: false,
            theme: termoraTheme(Brightness.light),
            darkTheme: termoraTheme(Brightness.dark),
            themeMode: _themeMode(widget.settings.settings.theme),
            themeAnimationDuration: Motion.panel,
            themeAnimationCurve: Motion.easeInOut,
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.3,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const RootShell(),
          ),
        );
      },
    );
  }
}
