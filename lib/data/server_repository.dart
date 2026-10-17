import 'package:flutter/foundation.dart';

import 'json_store.dart';
import 'models.dart';
import 'secret_store.dart';

const int kServersSchemaVersion = 1;

/// Keys under which a server's secrets live in the [SecretStore].
List<String> secretKeysFor(String serverId) => [
      'password:$serverId',
      'privateKey:$serverId',
      'passphrase:$serverId',
    ];

/// In-memory source of truth for servers and groups; writing to disk is a
/// side effect.
class ServerRepository extends ChangeNotifier {
  ServerRepository(this._store, {SecretStore? secrets}) : _secrets = secrets;

  final JsonStore _store;
  final SecretStore? _secrets;

  final List<ServerConfig> _servers = [];
  final List<ServerGroup> _groups = [];

  List<ServerConfig> get servers => List.unmodifiable(_servers);

  List<ServerGroup> get groups {
    final sorted = List<ServerGroup>.of(_groups)
      ..sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(sorted);
  }

  List<ServerConfig> get favorites {
    final list = _servers.where((s) => s.favorite).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  List<ServerConfig> get recents {
    final list = _servers.where((s) => s.lastConnectedAt != null).toList()
      ..sort((a, b) => b.lastConnectedAt!.compareTo(a.lastConnectedAt!));
    return list.take(5).toList();
  }

  List<ServerConfig> byGroup(String? groupId) =>
      _servers.where((s) => s.groupId == groupId).toList();

  ServerConfig? byId(String id) {
    for (final s in _servers) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> load() async {
    final data = await _store.read();
    _servers.clear();
    _groups.clear();
    if (data == null) {
      notifyListeners();
      return;
    }
    final rawGroups = data['groups'];
    if (rawGroups is List) {
      for (final entry in rawGroups) {
        if (entry is Map) {
          _groups.add(ServerGroup.fromJson(entry.cast<String, Object?>()));
        }
      }
    }
    final rawServers = data['servers'];
    if (rawServers is List) {
      for (final entry in rawServers) {
        if (entry is Map) {
          _servers.add(ServerConfig.fromJson(entry.cast<String, Object?>()));
        }
      }
    }
    notifyListeners();
  }

  Future<void> upsert(ServerConfig server) async {
    final index = _servers.indexWhere((s) => s.id == server.id);
    if (index == -1) {
      _servers.add(server);
    } else {
      _servers[index] = server;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _servers.removeWhere((s) => s.id == id);
    if (_secrets != null) {
      for (final key in secretKeysFor(id)) {
        await _secrets.delete(key);
      }
    }
    await _persist();
    notifyListeners();
  }

  Future<void> markConnected(String id, int atMillis) async {
    final index = _servers.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _servers[index] = _servers[index].copyWith(lastConnectedAt: atMillis);
    await _persist();
    notifyListeners();
  }

  /// Imports [incoming] servers and [groups], skipping servers whose
  /// `(host, port, username)` triple already exists. Returns the number of
  /// servers actually added. Persists once.
  Future<int> importAll(
    List<ServerConfig> incoming,
    List<ServerGroup> groups,
  ) async {
    final existing = _servers
        .map((s) => '${s.host}\u0000${s.port}\u0000${s.username}')
        .toSet();
    var added = 0;
    for (final server in incoming) {
      final key = '${server.host}\u0000${server.port}\u0000${server.username}';
      if (existing.contains(key)) continue;
      existing.add(key);
      _servers.add(server);
      added++;
    }
    for (final group in groups) {
      if (_groups.every((g) => g.id != group.id)) _groups.add(group);
    }
    if (added > 0 || groups.isNotEmpty) {
      await _persist();
      notifyListeners();
    }
    return added;
  }

  Future<void> upsertGroup(ServerGroup group) async {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index == -1) {
      _groups.add(group);
    } else {
      _groups[index] = group;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> removeGroup(String id) async {
    _groups.removeWhere((g) => g.id == id);
    for (var i = 0; i < _servers.length; i++) {
      if (_servers[i].groupId == id) {
        _servers[i] = _servers[i].copyWith(groupId: null);
      }
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.write({
      'schemaVersion': kServersSchemaVersion,
      'groups': _groups.map((g) => g.toJson()).toList(),
      'servers': _servers.map((s) => s.toJson()).toList(),
    });
  }
}
