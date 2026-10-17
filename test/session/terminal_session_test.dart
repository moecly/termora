import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:termora/data/models.dart';
import 'package:termora/session/session_status.dart';
import 'package:termora/session/terminal_session.dart';
import 'package:termora/ssh/ssh_connection.dart';

class FakeSshConnection implements SshConnection {
  final stdoutController = StreamController<List<int>>();
  final stderrController = StreamController<List<int>>();
  final List<List<int>> writes = [];
  final List<List<int>> resizes = [];
  final _done = Completer<void>();
  int stdoutCancelCount = 0;
  bool closed = false;
  Object? _failure;

  FakeSshConnection() {
    stdoutController.onCancel = () => stdoutCancelCount++;
  }

  void emit(String data) => stdoutController.add(utf8.encode(data));

  void failWith(Object error) {
    _failure = error;
    if (!_done.isCompleted) _done.complete();
  }

  void finishCleanly() {
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Stream<List<int>> get stdout => stdoutController.stream;

  @override
  Stream<List<int>> get stderr => stderrController.stream;

  @override
  void write(List<int> data) => writes.add(data);

  @override
  void resize(int width, int height, [int pixelWidth = 0, int pixelHeight = 0]) =>
      resizes.add([width, height, pixelWidth, pixelHeight]);

  @override
  Future<void> get done => _done.future;

  @override
  Object? get failure => _failure;

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

ServerConfig _server() => const ServerConfig(
      id: 'srv_1',
      name: 'local',
      host: '127.0.0.1',
      port: 2222,
      username: 'moecly',
      createdAt: 0,
    );

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeSshConnection fake;

  TerminalSession makeSession() {
    fake = FakeSshConnection();
    return TerminalSession(
      server: _server(),
      connector: ({required server, required width, required height}) async => fake,
      maxLines: 1000,
      onStatusChanged: (_) {},
    );
  }

  test('start moves status connecting -> connected', () async {
    final session = makeSession();
    final statuses = <SessionStatus>[];
    session.addListener(() => statuses.add(session.status));

    await session.start(width: 80, height: 24);

    expect(session.status, SessionStatus.connected);
    expect(statuses.first, SessionStatus.connecting);
    expect(statuses.last, SessionStatus.connected);
    session.dispose();
  });

  test('remote output is decoded and written to the buffer', () async {
    final session = makeSession();
    await session.start(width: 80, height: 24);

    fake.emit('hi\r\n');
    await _flush();

    expect(session.terminal.buffer.getText(null, true), contains('hi'));
    session.dispose();
  });

  test('local input is forwarded to the connection as utf8', () async {
    final session = makeSession();
    await session.start(width: 80, height: 24);

    session.terminal.textInput('x');

    expect(fake.writes.last, utf8.encode('x'));
    session.dispose();
  });

  test('terminal resize is forwarded to the connection', () async {
    final session = makeSession();
    await session.start(width: 80, height: 24);

    session.terminal.onResize?.call(120, 40, 0, 0);

    expect(fake.resizes.last, [120, 40, 0, 0]);
    session.dispose();
  });

  test('connection end marks the session disconnected with a message', () async {
    final session = makeSession();
    await session.start(width: 80, height: 24);

    fake.finishCleanly();
    await _flush();

    expect(session.status, SessionStatus.disconnected);
    expect(session.errorMessage, isNotNull);
    session.dispose();
  });

  test('unexpected failure is surfaced', () async {
    final session = makeSession();
    await session.start(width: 80, height: 24);

    fake.failWith(Exception('boom'));
    await _flush();

    expect(session.status, SessionStatus.disconnected);
    expect(session.errorMessage, isNotNull);
    session.dispose();
  });

  test('after disconnect no more data is written', () async {
    final session = makeSession();
    await session.start(width: 80, height: 24);
    await session.disconnect();

    final writesBefore = fake.writes.length;
    session.terminal.textInput('y');

    expect(fake.writes.length, writesBefore);
    session.dispose();
  });

  test('dispose cancels the stdout subscription', () async {
    final session = makeSession();
    await session.start(width: 80, height: 24);

    session.dispose();
    await _flush();

    expect(fake.stdoutCancelCount, 1);
  });

  test('connector error is reported as a failed session', () async {
    final session = TerminalSession(
      server: _server(),
      connector: ({required server, required width, required height}) async {
        throw Exception('cannot connect');
      },
      maxLines: 1000,
      onStatusChanged: (_) {},
    );

    await session.start(width: 80, height: 24);

    expect(session.status, SessionStatus.failed);
    expect(session.errorMessage, isNotNull);
    session.dispose();
  });
}
