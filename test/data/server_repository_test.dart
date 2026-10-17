import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termora/data/json_store.dart';
import 'package:termora/data/models.dart';
import 'package:termora/data/secret_store.dart';
import 'package:termora/data/server_repository.dart';

void main() {
  late Directory dir;
  late ServerRepository repo;
  late FileSecretStore secrets;

  ServerConfig server({
    String id = 'srv_1',
    String name = 'web',
    String host = '10.0.0.1',
    int port = 22,
    String username = 'root',
    String? groupId,
    bool favorite = false,
    int? lastConnectedAt,
  }) {
    return ServerConfig(
      id: id,
      name: name,
      host: host,
      port: port,
      username: username,
      groupId: groupId,
      favorite: favorite,
      lastConnectedAt: lastConnectedAt,
      createdAt: 1000,
    );
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('termora_repo');
    secrets = FileSecretStore(File('${dir.path}/secrets.json'));
    repo = ServerRepository(
      JsonStore(File('${dir.path}/servers.json')),
      secrets: secrets,
    );
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('upsert adds a new server and persists it', () async {
    await repo.upsert(server());
    expect(repo.servers, hasLength(1));

    final reloaded = ServerRepository(JsonStore(File('${dir.path}/servers.json')));
    await reloaded.load();
    expect(reloaded.servers.single.host, '10.0.0.1');
  });

  test('upsert updates an existing server in place', () async {
    await repo.upsert(server());
    await repo.upsert(server(name: 'web-renamed'));
    expect(repo.servers, hasLength(1));
    expect(repo.servers.single.name, 'web-renamed');
  });

  test('remove deletes the server and its secrets', () async {
    await repo.upsert(server());
    await secrets.write('password:srv_1', 'hunter2');
    await secrets.write('privateKey:srv_1', 'PEM');

    await repo.remove('srv_1');

    expect(repo.servers, isEmpty);
    expect(await secrets.read('password:srv_1'), isNull);
    expect(await secrets.read('privateKey:srv_1'), isNull);
  });

  test('importAll skips duplicate (host, port, username) triples', () async {
    await repo.upsert(server(id: 'srv_1', host: 'a', port: 22, username: 'x'));
    final added = await repo.importAll(
      [
        server(id: 'srv_2', host: 'a', port: 22, username: 'x'), // duplicate
        server(id: 'srv_3', host: 'a', port: 22, username: 'y'), // new
        server(id: 'srv_4', host: 'b', port: 22, username: 'x'), // new
      ],
      const [],
    );
    expect(added, 2);
    expect(repo.servers, hasLength(3));
  });

  test('recents returns at most 5, most recent first', () async {
    for (var i = 0; i < 7; i++) {
      await repo.upsert(server(id: 'srv_$i', host: 'h$i', lastConnectedAt: i * 100));
    }
    final recents = repo.recents;
    expect(recents, hasLength(5));
    expect(recents.first.lastConnectedAt, 600);
    expect(recents.last.lastConnectedAt, 200);
  });

  test('recents ignores servers never connected to', () async {
    await repo.upsert(server(id: 'srv_1', lastConnectedAt: null));
    expect(repo.recents, isEmpty);
  });

  test('favorites are filtered and sorted by name', () async {
    await repo.upsert(server(id: 'srv_1', name: 'zeta', favorite: true));
    await repo.upsert(server(id: 'srv_2', name: 'alpha', favorite: true, host: 'b'));
    await repo.upsert(server(id: 'srv_3', name: 'beta', favorite: false, host: 'c'));
    expect(repo.favorites.map((s) => s.name), ['alpha', 'zeta']);
  });

  test('removeGroup nulls the groupId of its servers', () async {
    await repo.upsertGroup(const ServerGroup(id: 'grp_1', name: 'Prod'));
    await repo.upsert(server(id: 'srv_1', groupId: 'grp_1'));

    await repo.removeGroup('grp_1');

    expect(repo.groups, isEmpty);
    expect(repo.servers.single.groupId, isNull);
  });

  test('byGroup(null) returns ungrouped servers', () async {
    await repo.upsert(server(id: 'srv_1', groupId: null));
    await repo.upsert(server(id: 'srv_2', groupId: 'grp_1', host: 'b'));
    expect(repo.byGroup(null).map((s) => s.id), ['srv_1']);
  });

  test('markConnected updates lastConnectedAt', () async {
    await repo.upsert(server());
    await repo.markConnected('srv_1', 4242);
    expect(repo.servers.single.lastConnectedAt, 4242);
  });
}
