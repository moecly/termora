import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termora/app/app.dart';
import 'package:termora/data/json_store.dart';
import 'package:termora/data/known_hosts_repository.dart';
import 'package:termora/data/models.dart';
import 'package:termora/data/secret_store.dart';
import 'package:termora/data/server_repository.dart';
import 'package:termora/data/settings_repository.dart';
import 'package:termora/design/app_theme.dart';
import 'package:termora/design/motion.dart';
import 'package:termora/session/session_manager.dart';
import 'package:termora/ssh/host_key_verifier.dart';
import 'package:termora/ui/common/prompts.dart';
import 'package:termora/ui/terminal/key_deck.dart';
import 'package:termora/ui/terminal/terminal_page.dart';
import 'package:termora/ui/terminal/terminal_viewport.dart';

class _MemorySecretStore implements SecretStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
  @override
  Future<void> deleteAll() async => _data.clear();
  @override
  Future<int> count() async => _data.length;
}

ServerConfig _server() => const ServerConfig(
  id: 'srv_test',
  name: 'Alpha',
  host: 'example.com',
  port: 22,
  username: 'root',
  createdAt: 0,
);

void main() {
  testWidgets('immersive mode hides and restores the chrome', (tester) async {
    final secrets = _MemorySecretStore();
    final servers = ServerRepository(JsonStore(File('/nonexistent/servers.json')));
    final settings = SettingsRepository(JsonStore(File('/nonexistent/settings.json')));
    final knownHosts =
        KnownHostsRepository(JsonStore(File('/nonexistent/known_hosts.json')));

    final navigatorKey = GlobalKey<NavigatorState>();
    final prompts = PromptQueue();
    final manager = SessionManager(
      servers: servers,
      settings: settings,
      connector: ({required server, required width, required height}) async {
        throw UnimplementedError();
      },
    );
    final verifier = HostKeyVerifier(
      knownHosts: knownHosts,
      navigatorKey: navigatorKey,
      queue: prompts,
    );

    final session = (await tester.runAsync(() => manager.connect(_server())))!;
    manager.activate(session.id);

    await tester.pumpWidget(MaterialApp(
      theme: termoraTheme(Brightness.dark),
      home: ServicesScope(
        manager: manager,
        secretStore: secrets,
        servers: servers,
        settings: settings,
        knownHosts: knownHosts,
        navigatorKey: navigatorKey,
        prompts: prompts,
        hostKeyVerifier: verifier,
        child: TerminalPage(sessionId: session.id),
      ),
    ));
    await tester.pump();

    expect(find.byType(KeyDeck), findsOneWidget);
    expect(tester.getSize(find.byType(KeyDeck)).height, greaterThan(0));

    // After the idle timeout the deck collapses to zero height.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(tester.getSize(find.byType(KeyDeck)).height, 0);

    // Any input restores the chrome.
    await tester.tap(find.byType(TerminalViewport));
    await tester.pump(Motion.panel);
    expect(tester.getSize(find.byType(KeyDeck)).height, greaterThan(0));

    // Disabling immersive mode keeps the chrome visible.
    await tester.runAsync(() => settings.update(
          settings.settings.copyWith(terminalImmersiveChrome: false),
        ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(tester.getSize(find.byType(KeyDeck)).height, greaterThan(0));
  });
}
