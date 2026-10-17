import 'dart:math';

/// How a server authenticates.
enum AuthMethod { password, privateKey }

final Random _rng = Random.secure();

String _randomId(String prefix) {
  final buf = StringBuffer(prefix);
  for (var i = 0; i < 8; i++) {
    buf.write(_rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buf.toString();
}

String newServerId() => _randomId('srv_');
String newGroupId() => _randomId('grp_');
String newSessionId() => _randomId('ses_');

/// A saved SSH server profile.
class ServerConfig {
  const ServerConfig({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.groupId,
    this.note,
    this.favorite = false,
    this.authMethod = AuthMethod.password,
    this.rememberPassword = false,
    this.rememberPassphrase = false,
    this.lastConnectedAt,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String? groupId;
  final String? note;
  final bool favorite;
  final AuthMethod authMethod;

  /// Only meaningful when [authMethod] is [AuthMethod.password].
  final bool rememberPassword;

  /// Only meaningful when [authMethod] is [AuthMethod.privateKey].
  final bool rememberPassphrase;

  /// Epoch millis of the last successful connection, or null.
  final int? lastConnectedAt;
  final int createdAt;

  ServerConfig copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    Object? groupId = _sentinel,
    Object? note = _sentinel,
    bool? favorite,
    AuthMethod? authMethod,
    bool? rememberPassword,
    bool? rememberPassphrase,
    Object? lastConnectedAt = _sentinel,
    int? createdAt,
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      groupId: groupId == _sentinel ? this.groupId : groupId as String?,
      note: note == _sentinel ? this.note : note as String?,
      favorite: favorite ?? this.favorite,
      authMethod: authMethod ?? this.authMethod,
      rememberPassword: rememberPassword ?? this.rememberPassword,
      rememberPassphrase: rememberPassphrase ?? this.rememberPassphrase,
      lastConnectedAt:
          lastConnectedAt == _sentinel ? this.lastConnectedAt : lastConnectedAt as int?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'username': username,
        'groupId': groupId,
        'note': note,
        'favorite': favorite,
        'authMethod': authMethod.name,
        'rememberPassword': rememberPassword,
        'rememberPassphrase': rememberPassphrase,
        'lastConnectedAt': lastConnectedAt,
        'createdAt': createdAt,
      };

  factory ServerConfig.fromJson(Map<String, Object?> json) {
    return ServerConfig(
      id: json['id']! as String,
      name: json['name']! as String,
      host: json['host']! as String,
      port: (json['port']! as num).toInt(),
      username: json['username']! as String,
      groupId: json['groupId'] as String?,
      note: json['note'] as String?,
      favorite: json['favorite'] as bool? ?? false,
      authMethod: AuthMethod.values.firstWhere(
        (m) => m.name == json['authMethod'],
        orElse: () => AuthMethod.password,
      ),
      rememberPassword: json['rememberPassword'] as bool? ?? false,
      rememberPassphrase: json['rememberPassphrase'] as bool? ?? false,
      lastConnectedAt: (json['lastConnectedAt'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ServerConfig &&
      other.id == id &&
      other.name == name &&
      other.host == host &&
      other.port == port &&
      other.username == username &&
      other.groupId == groupId &&
      other.note == note &&
      other.favorite == favorite &&
      other.authMethod == authMethod &&
      other.rememberPassword == rememberPassword &&
      other.rememberPassphrase == rememberPassphrase &&
      other.lastConnectedAt == lastConnectedAt &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, host, port, username, groupId, note,
      favorite, authMethod, rememberPassword, rememberPassphrase,
      lastConnectedAt, createdAt);
}

/// A named group servers can be filed under.
class ServerGroup {
  const ServerGroup({required this.id, required this.name, this.order = 0});

  final String id;
  final String name;
  final int order;

  ServerGroup copyWith({String? id, String? name, int? order}) => ServerGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        order: order ?? this.order,
      );

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'order': order};

  factory ServerGroup.fromJson(Map<String, Object?> json) => ServerGroup(
        id: json['id']! as String,
        name: json['name']! as String,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is ServerGroup && other.id == id && other.name == name && other.order == order;

  @override
  int get hashCode => Object.hash(id, name, order);
}

/// A remembered host public key.
class KnownHost {
  const KnownHost({
    required this.host,
    required this.port,
    required this.keyType,
    required this.fingerprint,
    required this.addedAt,
  });

  final String host;
  final int port;

  /// e.g. `ssh-ed25519`.
  final String keyType;

  /// Base64 fingerprint string as produced by dartssh2's `onVerifyHostKey`.
  final String fingerprint;
  final int addedAt;

  Map<String, Object?> toJson() => {
        'host': host,
        'port': port,
        'keyType': keyType,
        'fingerprint': fingerprint,
        'addedAt': addedAt,
      };

  factory KnownHost.fromJson(Map<String, Object?> json) => KnownHost(
        host: json['host']! as String,
        port: (json['port']! as num).toInt(),
        keyType: json['keyType']! as String,
        fingerprint: json['fingerprint']! as String,
        addedAt: (json['addedAt'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is KnownHost &&
      other.host == host &&
      other.port == port &&
      other.keyType == keyType &&
      other.fingerprint == fingerprint;

  @override
  int get hashCode => Object.hash(host, port, keyType, fingerprint);
}

const Object _sentinel = Object();
