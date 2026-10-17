import 'package:flutter/foundation.dart';

import 'json_store.dart';

const int kSettingsSchemaVersion = 1;

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
  });

  final ThemeSetting theme;

  /// 10..22, default 13.
  final double terminalFontSize;
  final String terminalThemeId;

  /// 1000..100000, default 5000.
  final int scrollbackLines;

  /// 0 disables keep-alive; default 30.
  final int keepAliveSeconds;

  /// 5..120, default 15.
  final int connectTimeoutSeconds;
  final bool rememberPasswordsByDefault;

  AppSettings copyWith({
    ThemeSetting? theme,
    double? terminalFontSize,
    String? terminalThemeId,
    int? scrollbackLines,
    int? keepAliveSeconds,
    int? connectTimeoutSeconds,
    bool? rememberPasswordsByDefault,
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
    );
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
      other.rememberPasswordsByDefault == rememberPasswordsByDefault;

  @override
  int get hashCode => Object.hash(theme, terminalFontSize, terminalThemeId,
      scrollbackLines, keepAliveSeconds, connectTimeoutSeconds,
      rememberPasswordsByDefault);
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
