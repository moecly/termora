import 'dart:io' show Directory, File;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termora/app/app.dart';
import 'package:termora/data/json_store.dart';
import 'package:termora/data/known_hosts_repository.dart';
import 'package:termora/data/models.dart';
import 'package:termora/data/secret_store.dart';
import 'package:termora/data/server_repository.dart';
import 'package:termora/data/settings_repository.dart';
import 'package:termora/session/session_manager.dart';
import 'package:termora/session/terminal_session.dart';
import 'package:termora/ssh/host_key_verifier.dart';
import 'package:termora/ui/common/prompts.dart';
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

void main() {
  testWidgets('two-finger pinch writes a larger terminal font size', (tester) async {
    final dir = Directory.systemTemp.createTempSync('termora_viewport');
    addTearDown(() => dir.deleteSync(recursive: true));

    final secrets = _MemorySecretStore();
    final servers = ServerRepository(JsonStore(File('/nonexistent/servers.json')));
    final settings =
        SettingsRepository(JsonStore(File('${dir.path}/settings.json')));
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
    final session = TerminalSession(
      server: const ServerConfig(
        id: 'srv_1',
        name: 'local',
        host: '127.0.0.1',
        port: 22,
        username: 'root',
        createdAt: 0,
      ),
      connector: ({required server, required width, required height}) async {
        throw UnimplementedError();
      },
      maxLines: 1000,
      onStatusChanged: (_) {},
    );

    await tester.pumpWidget(MaterialApp(
      home: ServicesScope(
        manager: manager,
        secretStore: secrets,
        servers: servers,
        settings: settings,
        knownHosts: knownHosts,
        navigatorKey: navigatorKey,
        prompts: prompts,
        hostKeyVerifier: verifier,
        child: Scaffold(
          body: TerminalViewport(session: session, settings: settings.settings),
        ),
      ),
    ));
    await tester.pump();

    expect(settings.settings.terminalFontSize, 13);

    final g1 = await tester.startGesture(const Offset(100, 100), pointer: 1);
    final g2 = await tester.startGesture(const Offset(200, 100), pointer: 2);
    await tester.pump();
    await g2.moveBy(const Offset(100, 0));
    await tester.pump();

    expect(settings.settings.terminalFontSize, 26);

    await g2.up();
    await g1.up();
    await tester.pump();
  });
}
