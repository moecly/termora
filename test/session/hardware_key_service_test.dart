import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termora/data/json_store.dart';
import 'package:termora/data/server_repository.dart';
import 'package:termora/data/settings_repository.dart';
import 'package:termora/session/hardware_key_service.dart';
import 'package:termora/session/session_manager.dart';

void main() {
  // The service name is duplicated here on purpose: MethodChannel identity is by
  // name, so a mock handler installed on this channel intercepts the service's.
  const channel = MethodChannel('termora/hardware_keys');

  test(
    'init and dispose are safe no-ops on non-Android hosts',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = Directory.systemTemp.createTempSync('termora_hardware_keys');
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        dir.deleteSync(recursive: true);
      });

      final servers = ServerRepository(
        JsonStore(File('${dir.path}/servers.json')),
      );
      final settings = SettingsRepository(
        JsonStore(File('${dir.path}/settings.json')),
      );
      final manager = SessionManager(
        servers: servers,
        settings: settings,
        connector: ({required server, required width, required height}) async {
          throw UnimplementedError();
        },
      );
      final service = HardwareKeyService(manager: manager, settings: settings);

      await service.init();
      // A settings change while connected pushes the intercepted key codes on
      // Android; on other hosts init never subscribes, so nothing is sent.
      await settings.update(settings.settings.copyWith(keepScreenOn: false));
      await Future<void>.delayed(Duration.zero);
      service.dispose();

      expect(calls, isEmpty);
    },
    skip: Platform.isAndroid ? 'Android subscribes and pushes instead' : false,
  );
}
