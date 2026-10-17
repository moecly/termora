import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termora/data/json_store.dart';
import 'package:termora/data/models.dart';
import 'package:termora/data/server_repository.dart';
import 'package:termora/data/settings_repository.dart';
import 'package:termora/session/session_manager.dart';
import 'package:termora/ssh/ssh_connection.dart';

class _FakeConnection implements SshConnection {
  final _stdout = StreamController<List<int>>();
  final _done = Completer<void>();
  bool closed = false;

  @override
  Stream<List<int>> get stdout => _stdout.stream;
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  void write(List<int> data) {}
  @override
  void resize(int width, int height, [int pixelWidth = 0, int pixelHeight = 0]) {}
  @override
  Future<void> get done => _done.future;
  @override
  Object? get failure => null;
  @override
  String? get authBanner => null;
  @override
  String? get remoteVersion => 'SSH-2.0-Fake';
  @override
  bool get isClosed => closed;
  @override
  Future<void> close() async {
    closed = true;
    if (!_done.isCompleted) _done.complete();
  }
}

const _server = ServerConfig(
  id: 'srv_1',
  name: 'local',
  host: '127.0.0.1',
  port: 2222,
  username: 'moecly',
  createdAt: 0,
);

void main() {
  late Directory dir;
  late ServerRepository servers;
  late SettingsRepository settings;
  late List<_FakeConnection> created;
  late int connectorCalls;
  late SessionManager manager;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('termora_sessions');
    servers = ServerRepository(JsonStore(File('${dir.path}/servers.json')));
    settings = SettingsRepository(JsonStore(File('${dir.path}/settings.json')));
    created = [];
    connectorCalls = 0;
    manager = SessionManager(
      servers: servers,
      settings: settings,
      connector: ({required server, required width, required height}) async {
        connectorCalls++;
        final conn = _FakeConnection();
        created.add(conn);
        return conn;
      },
    );
  });

  tearDown(() async {
    manager.dispose();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('second connect without force reuses the existing session', () async {
    final a = await manager.connect(_server);
    await a.start(width: 80, height: 24);
    final b = await manager.connect(_server);
    expect(identical(a, b), isTrue);
    expect(manager.sessions, hasLength(1));
    expect(connectorCalls, 1);
  });

  test('force connect creates a second session', () async {
    final a = await manager.connect(_server);
    await a.start(width: 80, height: 24);
    final b = await manager.connect(_server, force: true);
    await b.start(width: 80, height: 24);
    expect(identical(a, b), isFalse);
    expect(manager.sessions, hasLength(2));
    expect(connectorCalls, 2);
  });

  test('a failed session does not block a fresh connect', () async {
    final bad = await manager.connect(_server);
    await bad.disconnect();
    final fresh = await manager.connect(_server);
    expect(identical(bad, fresh), isFalse);
    expect(manager.sessions, hasLength(2));
  });

  test('activate switches the active session id', () async {
    final a = await manager.connect(_server);
    await a.start(width: 80, height: 24);
    final b = await manager.connect(_server, force: true);
    await b.start(width: 80, height: 24);

    manager.activate(a.id);

    expect(manager.activeSessionId, a.id);
    expect(manager.active?.id, a.id);
  });

  test('closeSession removes the session and closes its connection', () async {
    final a = await manager.connect(_server);
    await a.start(width: 80, height: 24);

    await manager.closeSession(a.id);

    expect(manager.sessions, isEmpty);
    expect(created.single.closed, isTrue);
    expect(manager.activeSessionId, isNull);
  });

  test('markConnected records the connection time', () async {
    await servers.upsert(_server);
    await manager.connect(_server);
    expect(servers.servers.single.lastConnectedAt, isNotNull);
  });
}
