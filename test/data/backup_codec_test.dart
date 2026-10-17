import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termora/data/backup_codec.dart';
import 'package:termora/data/models.dart';

ServerConfig _server(String id) => ServerConfig(
      id: id,
      name: 'prod-$id',
      host: '10.0.0.1',
      port: 22,
      username: 'root',
      groupId: 'grp_1',
      note: 'primary',
      favorite: true,
      authMethod: AuthMethod.privateKey,
      rememberPassphrase: true,
      lastConnectedAt: 1760000000000,
      createdAt: 1759000000000,
    );

void main() {
  group('BackupCodec', () {
    test('round-trips servers and groups', () {
      final encoded = BackupCodec.encode(
        servers: [_server('srv_1'), _server('srv_2')],
        groups: [const ServerGroup(id: 'grp_1', name: 'Prod', order: 3)],
      );
      final decoded = BackupCodec.decode(encoded);
      expect(decoded.servers, hasLength(2));
      expect(decoded.servers.first, _server('srv_1'));
      expect(decoded.groups.single.name, 'Prod');
      expect(decoded.groups.single.order, 3);
      expect(decoded.secrets, isEmpty);
    });

    test('decode without secrets yields an empty map', () {
      final encoded = BackupCodec.encode(servers: [_server('srv_1')], groups: const []);
      final decoded = BackupCodec.decode(encoded);
      expect(decoded.secrets, isEmpty);
    });

    test('secrets survive a round-trip with matching keys', () {
      final encoded = BackupCodec.encode(
        servers: [_server('srv_1')],
        groups: const [],
        secrets: {'password:srv_1': 'secret', 'passphrase:srv_1': 'phrase'},
      );
      final decoded = BackupCodec.decode(encoded);
      expect(decoded.secrets, {
        'password:srv_1': 'secret',
        'passphrase:srv_1': 'phrase',
      });
    });

    test('rejects a wrong format marker', () {
      final encoded = BackupCodec.encode(servers: const [], groups: const []);
      final tampered = encoded.replaceFirst('termora.backup', 'other.backup');
      expect(
        () => BackupCodec.decode(tampered),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an unsupported version', () {
      final encoded = BackupCodec.encode(servers: const [], groups: const []);
      final tampered = encoded.replaceFirst('"version": 1', '"version": 99');
      expect(
        () => BackupCodec.decode(tampered),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid JSON', () {
      expect(
        () => BackupCodec.decode('not json at all'),
        throwsA(isA<FormatException>()),
      );
    });

    test('produces a file another process can read', () async {
      final dir = await Directory.systemTemp.createTemp('termora_backup');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final file = File('${dir.path}/backup.json');
      await file.writeAsString(
        BackupCodec.encode(servers: [_server('srv_1')], groups: const []),
      );
      final decoded = BackupCodec.decode(await file.readAsString());
      expect(decoded.servers.single.id, 'srv_1');
    });
  });
}
