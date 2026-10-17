import 'package:flutter/foundation.dart';

import 'json_store.dart';
import 'models.dart';

const int kKnownHostsSchemaVersion = 1;

/// Remembered host public keys, keyed by host:port.
class KnownHostsRepository extends ChangeNotifier {
  KnownHostsRepository(this._store);

  final JsonStore _store;

  final List<KnownHost> _entries = [];

  List<KnownHost> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    final data = await _store.read();
    _entries.clear();
    if (data != null) {
      final raw = data['entries'];
      if (raw is List) {
        for (final entry in raw) {
          if (entry is Map) {
            _entries.add(KnownHost.fromJson(entry.cast<String, Object?>()));
          }
        }
      }
    }
    notifyListeners();
  }

  KnownHost? lookup(String host, int port) {
    for (final entry in _entries) {
      if (entry.host == host && entry.port == port) return entry;
    }
    return null;
  }

  /// Stores [host], overwriting any existing entry for the same host:port.
  Future<void> remember(KnownHost host) async {
    _entries.removeWhere((e) => e.host == host.host && e.port == host.port);
    _entries.add(host);
    await _persist();
    notifyListeners();
  }

  /// Clears all entries; returns the number removed.
  Future<int> clearAll() async {
    final removed = _entries.length;
    _entries.clear();
    await _persist();
    notifyListeners();
    return removed;
  }

  Future<void> _persist() async {
    await _store.write({
      'schemaVersion': kKnownHostsSchemaVersion,
      'entries': _entries.map((e) => e.toJson()).toList(),
    });
  }
}
