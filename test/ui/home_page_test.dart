import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termora/app/app.dart';
import 'package:termora/data/json_store.dart';
import 'package:termora/data/known_hosts_repository.dart';
import 'package:termora/data/secret_store.dart';
import 'package:termora/data/server_repository.dart';
import 'package:termora/data/settings_repository.dart';
import 'package:termora/design/app_theme.dart';
import 'package:termora/session/session_manager.dart';
import 'package:termora/ssh/host_key_verifier.dart';
import 'package:termora/ui/common/prompts.dart';
import 'package:termora/ui/home/home_page.dart';

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

Widget _harness(ServerRepository servers) {
  final secrets = _MemorySecretStore();
  final settings = SettingsRepository(JsonStore(File('/nonexistent/settings.json')));
  final knownHosts = KnownHostsRepository(JsonStore(File('/nonexistent/known_hosts.json')));

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

  return MaterialApp(
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
      child: const HomePage(),
    ),
  );
}

void main() {
  testWidgets('a connected ungrouped server is listed exactly once', (tester) async {
    final dir = Directory.systemTemp.createTempSync('termora_home');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/servers.json')
      ..writeAsStringSync(jsonEncode({
        'schemaVersion': 1,
        'servers': [
          {
            'id': 'srv_1',
            'name': 'Alpha',
            'host': 'alpha.example',
            'port': 22,
            'username': 'root',
            'groupId': null,
            'favorite': false,
            'authMethod': 'password',
            'lastConnectedAt': 1,
            'createdAt': 0,
          },
        ],
        'groups': <Object>[],
      }));

    final servers = ServerRepository(JsonStore(file));
    await tester.runAsync(servers.load);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(_harness(servers));
      await tester.pump();

      expect(find.text('Alpha'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('empty state shows a single 新增服务器 action', (tester) async {
    final servers = ServerRepository(JsonStore(File('/nonexistent/servers.json')));

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(_harness(servers));
      await tester.pump();

      expect(find.text('还没有服务器'), findsOneWidget);
      expect(find.text('新增服务器'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('removing the last server does not throw', (tester) async {
    final dir = Directory.systemTemp.createTempSync('termora_home');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/servers.json')
      ..writeAsStringSync(jsonEncode({
        'schemaVersion': 1,
        'servers': [
          {
            'id': 'srv_1',
            'name': 'Alpha',
            'host': 'alpha.example',
            'port': 22,
            'username': 'root',
            'groupId': null,
            'favorite': false,
            'authMethod': 'password',
            'lastConnectedAt': null,
            'createdAt': 0,
          },
        ],
        'groups': <Object>[],
      }));

    final servers = ServerRepository(JsonStore(file));
    await tester.runAsync(servers.load);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(_harness(servers));
      await tester.pump();
      expect(find.text('Alpha'), findsOneWidget);

      await tester.runAsync(() => servers.remove('srv_1'));
      await tester.pump();

      expect(find.text('还没有服务器'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
