import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termora/data/json_store.dart';
import 'package:termora/data/key_mapping.dart';
import 'package:termora/data/settings_repository.dart';

void main() {
  late Directory dir;
  late File file;
  late SettingsRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('termora_settings');
    file = File('${dir.path}/settings.json');
    repo = SettingsRepository(JsonStore(file));
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('defaults are used when fields are missing', () async {
    await file.writeAsString(jsonEncode({'schemaVersion': 1}));
    await repo.load();
    expect(repo.settings.terminalFontSize, 13);
    expect(repo.settings.keepAliveSeconds, 30);
    expect(repo.settings.connectTimeoutSeconds, 15);
    expect(repo.settings.theme, ThemeSetting.system);
    expect(repo.settings.terminalThemeId, 'termoraDark');
    expect(repo.settings.scrollbackLines, 5000);
    expect(repo.settings.rememberPasswordsByDefault, isFalse);
    expect(repo.settings.keepScreenOn, isTrue);
    expect(repo.settings.terminalImmersiveChrome, isTrue);
    expect(
      repo.settings.keyMappings,
      const [KeyMapping(source: 'volumeDown', action: 'ctrl')],
    );
  });

  test('custom key mappings persist and reload identically', () async {
    const next = AppSettings(
      keyMappings: [KeyMapping(source: 'volumeUp', action: 'escape')],
    );
    await repo.update(next);

    final reloaded = SettingsRepository(JsonStore(file));
    await reloaded.load();
    expect(reloaded.settings.keyMappings, next.keyMappings);
    expect(reloaded.settings.keepScreenOn, isTrue);
  });

  test('malformed key mappings fall back to defaults', () async {
    await file.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'keyMappings': [
        {'source': 'bogus'},
        'not-a-map',
      ],
    }));
    await repo.load();
    expect(repo.settings.keyMappings, kDefaultKeyMappings);
  });

  test('update persists and reloads identically', () async {
    const next = AppSettings(
      theme: ThemeSetting.dark,
      terminalFontSize: 18,
      terminalThemeId: 'oneDark',
      scrollbackLines: 20000,
      keepAliveSeconds: 0,
      connectTimeoutSeconds: 60,
      rememberPasswordsByDefault: true,
    );
    await repo.update(next);
    expect(repo.settings, next);

    final reloaded = SettingsRepository(JsonStore(file));
    await reloaded.load();
    expect(reloaded.settings, next);
  });

  test('a higher schemaVersion does not throw', () async {
    await file.writeAsString(jsonEncode({
      'schemaVersion': 99,
      'terminalFontSize': 15,
      'unknownField': 'ignored',
    }));
    await repo.load();
    expect(repo.settings.terminalFontSize, 15);
  });

  test('missing file yields defaults', () async {
    await repo.load();
    expect(repo.settings, const AppSettings());
  });
}
