@Tags(['integration'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termora/data/json_store.dart';
import 'package:termora/data/known_hosts_repository.dart';
import 'package:termora/data/models.dart';
import 'package:termora/ssh/auth_config.dart';
import 'package:termora/ssh/dart_ssh_connection.dart';
import 'package:termora/ssh/host_key_verifier.dart';
import 'package:termora/ssh/ssh_connection.dart';

const String kSshdRoot = '/tmp/termora-sshd';
const int kPort = 2222;

/// Collects the connection's output so tests can wait for a substring.
class _Collector {
  _Collector(SshConnection connection) {
    _sub = connection.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(_buffer.write);
  }

  final StringBuffer _buffer = StringBuffer();
  late final StreamSubscription<String> _sub;

  String get text => _buffer.toString();

  Future<void> waitFor(String needle, {Duration timeout = const Duration(seconds: 10)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (text.contains(needle)) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('timed out waiting for "$needle" in output:\n$text');
  }

  Future<void> cancel() => _sub.cancel();
}

/// The integration suite needs the throwaway sshd from tool/local-sshd.sh.
/// That sshd runs in debug mode, serves one connection and then exits, so
/// requiring the fixture keys to exist is not enough: also require the process
/// recorded in `sshd.pid` to still be alive. Otherwise a plain `flutter test`
/// would try to run these and fail after the sshd has served a connection.
String? _skipReason() {
  if (!File('$kSshdRoot/client_ed25519').existsSync()) {
    return 'needs a local sshd; run `just sshd-up` first';
  }
  final pidFile = File('$kSshdRoot/sshd.pid');
  final pid = pidFile.existsSync() ? int.tryParse(pidFile.readAsStringSync().trim()) : null;
  if (pid == null || !Directory('/proc/$pid').existsSync()) {
    return 'no local sshd is listening; run `just sshd-up` first';
  }
  return null;
}

void main() {
  final skipReason = _skipReason();

  test('real sshd: key auth, TERM, and PTY resize', () async {
    final dir = await Directory.systemTemp.createTemp('termora_e2e');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final user = Platform.environment['USER'] ?? Platform.environment['LOGNAME'] ?? 'root';
    const server = ServerConfig(
      id: 'srv_e2e',
      name: 'local-sshd',
      host: '127.0.0.1',
      port: kPort,
      username: '',
      createdAt: 0,
    );

    final verifier = HostKeyVerifier(
      knownHosts: KnownHostsRepository(JsonStore(File('${dir.path}/known_hosts.json'))),
      navigatorKey: GlobalKey<NavigatorState>(),
      decide: (host, port, keyType, fingerprint) async => true,
    );

    final connection = await DartSshConnection.connect(
      server: server.copyWith(username: user),
      auth: AuthConfig(
        method: AuthMethod.privateKey,
        privateKeyPem: File('$kSshdRoot/client_ed25519').readAsStringSync(),
      ),
      verifier: verifier,
      connectTimeout: const Duration(seconds: 15),
      keepAliveSeconds: 0,
    );
    addTearDown(connection.close);

    await connection.openShell(width: 100, height: 30);
    final collector = _Collector(connection);
    addTearDown(collector.cancel);

    connection.write(utf8.encode('echo \$TERM\r'));
    await collector.waitFor('xterm-256color');

    connection.write(utf8.encode('stty size\r'));
    await collector.waitFor('30 100');

    connection.resize(120, 40);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    connection.write(utf8.encode('stty size\r'));
    await collector.waitFor('40 120');

    await connection.close();
    await connection.done;
  }, skip: skipReason);
}
