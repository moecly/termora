import 'dart:convert';

import 'models.dart';

/// Decoded backup payload.
class BackupData {
  BackupData({
    required this.servers,
    required this.groups,
    required this.secrets,
  });

  final List<ServerConfig> servers;
  final List<ServerGroup> groups;

  /// Keys look like `password:<serverId>`, `privateKey:<serverId>`,
  /// `passphrase:<serverId>` (using the exporting side's server ids).
  final Map<String, String> secrets;
}

/// Encodes/decodes the Termora backup file format. Pure functions so they are
/// trivially unit-testable.
class BackupCodec {
  static const String format = 'termora.backup';
  static const int version = 1;

  static String encode({
    required List<ServerConfig> servers,
    required List<ServerGroup> groups,
    Map<String, String>? secrets,
  }) {
    final payload = <String, Object?>{
      'format': format,
      'version': version,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'groups': groups.map((g) => g.toJson()).toList(),
      'servers': servers.map((s) => s.toJson()).toList(),
    };
    if (secrets != null) {
      payload['secrets'] = secrets;
    }
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static BackupData decode(String json) {
    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const FormatException('备份文件不是合法的 JSON');
    }
    if (decoded is! Map) {
      throw const FormatException('备份文件结构非法：顶层不是对象');
    }
    final map = decoded.cast<String, Object?>();
    if (map['format'] != format) {
      throw const FormatException('备份文件格式不匹配：缺少 termora.backup 标识');
    }
    final fileVersion = map['version'];
    if (fileVersion is! num) {
      throw const FormatException('备份文件缺少版本号');
    }
    if (fileVersion.toInt() != version) {
      throw FormatException('备份文件版本不支持：$fileVersion');
    }

    final servers = <ServerConfig>[];
    final rawServers = map['servers'];
    if (rawServers is List) {
      for (final entry in rawServers) {
        if (entry is Map) {
          servers.add(ServerConfig.fromJson(entry.cast<String, Object?>()));
        }
      }
    }

    final groups = <ServerGroup>[];
    final rawGroups = map['groups'];
    if (rawGroups is List) {
      for (final entry in rawGroups) {
        if (entry is Map) {
          groups.add(ServerGroup.fromJson(entry.cast<String, Object?>()));
        }
      }
    }

    final secrets = <String, String>{};
    final rawSecrets = map['secrets'];
    if (rawSecrets is Map) {
      rawSecrets.forEach((key, value) {
        if (key is String && value is String) secrets[key] = value;
      });
    }

    return BackupData(servers: servers, groups: groups, secrets: secrets);
  }
}
