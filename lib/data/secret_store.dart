import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_paths.dart';
import 'json_store.dart';

/// Key naming convention (global, unique). These keys must never appear in any
/// log or export file unless the user explicitly opts in.
///
/// - `password:<serverId>`    plaintext login password
/// - `privateKey:<serverId>`  full PEM private key
/// - `passphrase:<serverId>`  private key passphrase
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<int> count();
}

/// Reads/writes secrets through the OS keychain (Android/iOS/macOS/Windows).
class PlatformSecretStore implements SecretStore {
  PlatformSecretStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();

  @override
  Future<int> count() async {
    final all = await _storage.readAll();
    return all.length;
  }
}

/// Linux desktop fallback: a mode-0600 JSON file under the app data directory.
class FileSecretStore implements SecretStore {
  FileSecretStore(this.file) : _store = JsonStore(file);

  final File file;
  final JsonStore _store;

  Future<Map<String, String>> _load() async {
    final data = await _store.read();
    if (data == null) return <String, String>{};
    final result = <String, String>{};
    data.forEach((key, value) {
      if (value is String) result[key] = value;
    });
    return result;
  }

  @override
  Future<String?> read(String key) async => (await _load())[key];

  @override
  Future<void> write(String key, String value) async {
    final data = await _load();
    data[key] = value;
    await _save(data);
  }

  @override
  Future<void> delete(String key) async {
    final data = await _load();
    if (data.remove(key) != null) await _save(data);
  }

  @override
  Future<void> deleteAll() async {
    if (await file.exists()) await file.delete();
  }

  @override
  Future<int> count() async => (await _load()).length;

  Future<void> _save(Map<String, String> data) async {
    await _store.write(data.cast<String, Object?>());
    if (!Platform.isWindows) {
      try {
        await Process.run('chmod', ['600', file.path]);
      } on ProcessException {
        // Best effort; the file lives in the app-private data directory.
      }
    }
  }
}

const String _probeKey = '__termora_probe__';

/// Probes the OS keychain with a canary write/read/delete.
///
/// On success returns a [PlatformSecretStore]. On failure: on Linux, falls back
/// to a [FileSecretStore] and prints an explicit warning; on every other
/// platform the error is rethrown (better to fail loudly than silently
/// downgrade security).
Future<SecretStore> resolveSecretStore(AppPaths paths) async {
  final platformStore = PlatformSecretStore();
  try {
    await platformStore.write(_probeKey, '1');
    final readBack = await platformStore.read(_probeKey);
    await platformStore.delete(_probeKey);
    if (readBack != '1') {
      throw StateError('secret store probe returned $readBack');
    }
    return platformStore;
  } catch (error) {
    if (Platform.isLinux) {
      debugPrint(
        '[termora] WARNING: OS keychain unavailable ($error). '
        'Falling back to a local secrets.json file (Linux desktop only).',
      );
      return FileSecretStore(paths.fallbackSecretsFile);
    }
    rethrow;
  }
}

/// Decodes secrets from an imported backup file, ignoring malformed entries.
Map<String, String> decodeSecrets(Object? raw) {
  if (raw is! Map) return const {};
  final result = <String, String>{};
  raw.forEach((key, value) {
    if (key is String && value is String) result[key] = value;
  });
  return result;
}

/// Encodes a secret map for export.
Map<String, Object?> encodeSecrets(Map<String, String> secrets) =>
    secrets.map((key, value) => MapEntry(key, value as Object?));
