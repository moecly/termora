import 'package:flutter/foundation.dart';

import 'json_store.dart';
import 'key_mapping.dart';

const int kSettingsSchemaVersion = 1;

/// Terminal font size bounds (pt), shared by the settings slider and pinch zoom.
const double kTerminalFontSizeMin = 8;
const double kTerminalFontSizeMax = 28;

const List<KeyMapping> kDefaultKeyMappings = [
  KeyMapping(source: 'volumeDown', action: 'ctrl'),
];

enum ThemeSetting { system, light, dark }

/// User-configurable application settings. Missing fields fall back to
/// defaults; unknown fields are ignored (forward compatibility).
class AppSettings {
  const AppSettings({
    this.theme = ThemeSetting.system,
    this.terminalFontSize = 13,
    this.terminalThemeId = 'termoraDark',
    this.scrollbackLines = 5000,
    this.keepAliveSeconds = 30,
    this.connectTimeoutSeconds = 15,
    this.rememberPasswordsByDefault = false,
    this.keepScreenOn = true,
    this.keyMappings = kDefaultKeyMappings,
  });

  final ThemeSetting theme;

  /// 8..28, default 13.
  final double terminalFontSize;
  final String terminalThemeId;

  /// 1000..100000, default 5000.
  final int scrollbackLines;

  /// 0 disables keep-alive; default 30.
  final int keepAliveSeconds;

  /// 5..120, default 15.
  final int connectTimeoutSeconds;
  final bool rememberPasswordsByDefault;

  /// Keeps the screen awake while a terminal session is open.
  final bool keepScreenOn;

  /// Android hardware-key → terminal-action mappings.
  final List<KeyMapping> keyMappings;

  AppSettings copyWith({
    ThemeSetting? theme,
    double? terminalFontSize,
    String? terminalThemeId,
    int? scrollbackLines,
    int? keepAliveSeconds,
    int? connectTimeoutSeconds,
    bool? rememberPasswordsByDefault,
    bool? keepScreenOn,
    List<KeyMapping>? keyMappings,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      terminalFontSize: terminalFontSize ?? this.terminalFontSize,
      terminalThemeId: terminalThemeId ?? this.terminalThemeId,
      scrollbackLines: scrollbackLines ?? this.scrollbackLines,
      keepAliveSeconds: keepAliveSeconds ?? this.keepAliveSeconds,
      connectTimeoutSeconds: connectTimeoutSeconds ?? this.connectTimeoutSeconds,
      rememberPasswordsByDefault:
          rememberPasswordsByDefault ?? this.rememberPasswordsByDefault,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      keyMappings: keyMappings ?? this.keyMappings,
    );
  }

  Map<String, Object?> toJson() => {
        'theme': theme.name,
        'terminalFontSize': terminalFontSize,
        'terminalThemeId': terminalThemeId,
        'scrollbackLines': scrollbackLines,
        'keepAliveSeconds': keepAliveSeconds,
        'connectTimeoutSeconds': connectTimeoutSeconds,
        'rememberPasswordsByDefault': rememberPasswordsByDefault,
        'keepScreenOn': keepScreenOn,
        'keyMappings': keyMappings.map((m) => m.toJson()).toList(),
      };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    const defaults = AppSettings();
    return AppSettings(
      theme: ThemeSetting.values.firstWhere(
        (t) => t.name == json['theme'],
        orElse: () => defaults.theme,
      ),
      terminalFontSize:
          (json['terminalFontSize'] as num?)?.toDouble() ?? defaults.terminalFontSize,
      terminalThemeId: json['terminalThemeId'] as String? ?? defaults.terminalThemeId,
      scrollbackLines:
          (json['scrollbackLines'] as num?)?.toInt() ?? defaults.scrollbackLines,
      keepAliveSeconds:
          (json['keepAliveSeconds'] as num?)?.toInt() ?? defaults.keepAliveSeconds,
      connectTimeoutSeconds:
          (json['connectTimeoutSeconds'] as num?)?.toInt() ?? defaults.connectTimeoutSeconds,
      rememberPasswordsByDefault:
          json['rememberPasswordsByDefault'] as bool? ?? defaults.rememberPasswordsByDefault,
      keepScreenOn: json['keepScreenOn'] as bool? ?? defaults.keepScreenOn,
      keyMappings: _parseKeyMappings(json['keyMappings']) ?? defaults.keyMappings,
    );
  }

  static List<KeyMapping>? _parseKeyMappings(Object? raw) {
    if (raw is! List) return null;
    final parsed = <KeyMapping>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = entry.cast<String, Object?>();
      final source = map['source'];
      final action = map['action'];
      if (source is! String || action is! String) continue;
      parsed.add(KeyMapping(source: source, action: action));
    }
    return parsed.isEmpty ? null : parsed;
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.theme == theme &&
      other.terminalFontSize == terminalFontSize &&
      other.terminalThemeId == terminalThemeId &&
      other.scrollbackLines == scrollbackLines &&
      other.keepAliveSeconds == keepAliveSeconds &&
      other.connectTimeoutSeconds == connectTimeoutSeconds &&
      other.rememberPasswordsByDefault == rememberPasswordsByDefault &&
      other.keepScreenOn == keepScreenOn &&
      listEquals(other.keyMappings, keyMappings);

  @override
  int get hashCode => Object.hash(
        theme,
        terminalFontSize,
        terminalThemeId,
        scrollbackLines,
        keepAliveSeconds,
        connectTimeoutSeconds,
        rememberPasswordsByDefault,
        keepScreenOn,
        Object.hashAll(keyMappings),
      );
}

class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._store);

  final JsonStore _store;

  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> load() async {
    final data = await _store.read();
    if (data == null) {
      notifyListeners();
      return;
    }
    _settings = AppSettings.fromJson(data);
    notifyListeners();
  }

  Future<void> update(AppSettings next) async {
    _settings = next;
    await _store.write({
      'schemaVersion': kSettingsSchemaVersion,
      ...next.toJson(),
    });
    notifyListeners();
  }
}
