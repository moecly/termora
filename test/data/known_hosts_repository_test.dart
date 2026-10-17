import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termora/data/json_store.dart';
import 'package:termora/data/known_hosts_repository.dart';
import 'package:termora/data/models.dart';

void main() {
  late Directory dir;
  late KnownHostsRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('termora_kh');
    repo = KnownHostsRepository(JsonStore(File('${dir.path}/known_hosts.json')));
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('lookup returns null when nothing is remembered', () {
    expect(repo.lookup('h', 22), isNull);
  });

  test('remember stores an entry retrievable by host and port', () async {
    await repo.remember(
      const KnownHost(
        host: 'h',
        port: 22,
        keyType: 'ssh-ed25519',
        fingerprint: 'SHA256:AAA',
        addedAt: 1,
      ),
    );
    expect(repo.lookup('h', 22)?.fingerprint, 'SHA256:AAA');
    expect(repo.lookup('h', 2222), isNull);
  });

  test('remember overwrites the same host:port rather than appending', () async {
    await repo.remember(
      const KnownHost(host: 'h', port: 22, keyType: 'ssh-rsa', fingerprint: 'FIRST', addedAt: 1),
    );
    await repo.remember(
      const KnownHost(host: 'h', port: 22, keyType: 'ssh-ed25519', fingerprint: 'SECOND', addedAt: 2),
    );
    expect(repo.entries, hasLength(1));
    expect(repo.lookup('h', 22)?.fingerprint, 'SECOND');
  });

  test('clearAll reports the count and empties the store', () async {
    await repo.remember(
      const KnownHost(host: 'a', port: 22, keyType: 't', fingerprint: 'f1', addedAt: 1),
    );
    await repo.remember(
      const KnownHost(host: 'b', port: 22, keyType: 't', fingerprint: 'f2', addedAt: 1),
    );
    expect(await repo.clearAll(), 2);
    expect(repo.entries, isEmpty);
    expect(repo.lookup('a', 22), isNull);
  });

  test('persists across reloads', () async {
    await repo.remember(
      const KnownHost(host: 'h', port: 22, keyType: 't', fingerprint: 'f', addedAt: 1),
    );
    final reloaded = KnownHostsRepository(JsonStore(File('${dir.path}/known_hosts.json')));
    await reloaded.load();
    expect(reloaded.lookup('h', 22)?.fingerprint, 'f');
  });
}
