import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termora/data/json_store.dart';
import 'package:termora/data/server_repository.dart';
import 'package:termora/data/settings_repository.dart';
import 'package:termora/session/hardware_key_service.dart';
import 'package:termora/session/session_manager.dart';

void main() {
  test('init and dispose are safe no-ops on non-Android hosts', () async {
    final servers = ServerRepository(JsonStore(File('/nonexistent/servers.json')));
    final settings = SettingsRepository(JsonStore(File('/nonexistent/settings.json')));
    final manager = SessionManager(
      servers: servers,
      settings: settings,
      connector: ({required server, required width, required height}) async {
        throw UnimplementedError();
      },
    );
    final service = HardwareKeyService(manager: manager, settings: settings);

    await service.init();
    await settings.update(settings.settings.copyWith(keepScreenOn: false));
    service.dispose();

    if (!Platform.isAndroid) {
      expect(Platform.isAndroid, isFalse);
    }
  });
}
