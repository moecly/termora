import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termora/app/app.dart';
import 'package:termora/app/root_shell.dart';
import 'package:termora/data/json_store.dart';
import 'package:termora/data/known_hosts_repository.dart';
import 'package:termora/data/secret_store.dart';
import 'package:termora/data/server_repository.dart';
import 'package:termora/data/settings_repository.dart';
import 'package:termora/design/app_theme.dart';
import 'package:termora/session/session_manager.dart';
import 'package:termora/ssh/host_key_verifier.dart';
import 'package:termora/ui/common/prompts.dart';

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

Widget _harness() {
  final secrets = _MemorySecretStore();
  final servers = ServerRepository(JsonStore(File('/nonexistent/servers.json')));
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
      child: const RootShell(),
    ),
  );
}

void main() {
  testWidgets('sidebar collapses to 64 and expands back to 280', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(_harness());
      await tester.pump();

      final sidebar = find.byKey(const ValueKey('server-sidebar'));
      expect(tester.getSize(sidebar).width, 280);
      expect(find.text('Termora'), findsOneWidget);
      expect(find.text('导出'), findsOneWidget);

      await tester.tap(find.byTooltip('折叠侧栏'));
      await tester.pumpAndSettle();

      expect(tester.getSize(sidebar).width, 64);
      expect(find.text('Termora'), findsNothing);
      expect(find.text('导出'), findsNothing);

      await tester.tap(find.byTooltip('展开侧栏'));
      await tester.pumpAndSettle();

      expect(tester.getSize(sidebar).width, 280);
      expect(find.text('Termora'), findsOneWidget);
      expect(find.text('导出'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
