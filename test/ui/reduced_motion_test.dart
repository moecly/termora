import 'dart:io' show File;

import 'package:animations/animations.dart';
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

void main() {
  testWidgets('reduced motion renders home and skips route transitions', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

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

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: termoraTheme(Brightness.dark),
          navigatorKey: navigatorKey,
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
        ),
      );
      await tester.pump();

      expect(find.text('还没有服务器'), findsOneWidget);
      expect(tester.takeException(), isNull);

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Center(child: Text('PUSHED'))),
        ),
      );
      await tester.pump();
      await tester.pump();

      // The shared-axis transition is skipped entirely under reduced motion.
      expect(find.text('PUSHED'), findsOneWidget);
      expect(find.byType(SharedAxisTransition), findsNothing);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
