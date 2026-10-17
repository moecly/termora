import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../data/models.dart';
import 'auth_config.dart';
import 'host_key_verifier.dart';
import 'ssh_connection.dart';

/// Real [SshConnection] backed by dartssh2's [SSHClient] + [SSHSession].
class DartSshConnection implements SshConnection {
  DartSshConnection._(this._client);

  final SSHClient _client;
  SSHSession? _session;

  final _stdoutController = StreamController<List<int>>.broadcast();
  StreamSubscription<Uint8List>? _stdoutSub;
  StreamSubscription<Uint8List>? _stderrSub;
  final _stderrController = StreamController<List<int>>.broadcast();

  Completer<void>? _doneCompleter;
  Object? _failure;
  String? _authBanner;
  bool _closed = false;

  /// Connects and authenticates (but does not open a shell yet).
  static Future<DartSshConnection> connect({
    required ServerConfig server,
    required AuthConfig auth,
    required HostKeyVerifier verifier,
    required Duration connectTimeout,
    required int keepAliveSeconds,
    Future<String?> Function()? passwordRequest,
    Future<List<String>?> Function(SSHUserInfoRequest request)? userInfoRequest,
  }) async {
    final socket = await SSHSocket.connect(
      server.host,
      server.port,
      timeout: connectTimeout,
    );

    List<SSHKeyPair>? identities;
    if (auth.method == AuthMethod.privateKey && auth.privateKeyPem != null) {
      // Decoded on the main isolate: the PEM decoder itself is pure Dart, and
      // moving it into `Isolate.run` would capture the enclosing (unsendable)
      // connection context. bcrypt-based OpenSSH decryption may block briefly;
      // the UI already shows a connecting state.
      identities = SSHKeyPair.fromPem(auth.privateKeyPem!, auth.passphrase);
    }

    late final DartSshConnection connection;
    final client = SSHClient(
      socket,
      username: server.username,
      identities: identities,
      onVerifyHostKey: (type, fingerprint) =>
          verifier.verify(server.host, server.port, type, utf8.decode(fingerprint)),
      onPasswordRequest: passwordRequest,
      onUserInfoRequest: userInfoRequest,
      onUserauthBanner: (banner) {
        connection._authBanner = banner;
      },
      keepAliveInterval:
          keepAliveSeconds == 0 ? null : Duration(seconds: keepAliveSeconds),
      handshakeTimeout: connectTimeout,
      authTimeout: connectTimeout,
      ident: 'Termora_1.0',
      printDebug: kDebugMode ? (m) => debugPrint('[ssh] $m') : null,
    );
    connection = DartSshConnection._(client);

    connection._doneCompleter = Completer<void>();
    unawaited(
      connection._client.done.then(
        (_) {
          connection._closed = true;
          if (!connection._doneCompleter!.isCompleted) {
            connection._doneCompleter!.complete();
          }
        },
        onError: (Object error) {
          connection._failure = error;
          connection._closed = true;
          if (!connection._doneCompleter!.isCompleted) {
            connection._doneCompleter!.complete();
          }
        },
      ),
    );

    await connection._client.authenticated;
    return connection;
  }

  /// Opens a shell with the given PTY size.
  Future<void> openShell({required int width, required int height}) async {
    final session = await _client.shell(
      pty: SSHPtyConfig(type: 'xterm-256color', width: width, height: height),
    );
    _session = session;
    session.resizeTerminal(width, height);
    _stdoutSub = session.stdout.listen(_stdoutController.add);
    _stderrSub = session.stderr.listen(_stderrController.add);
  }

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => _stderrController.stream;

  @override
  void write(List<int> data) {
    if (_closed) return;
    _session?.write(Uint8List.fromList(data));
  }

  @override
  void resize(int width, int height, [int pixelWidth = 0, int pixelHeight = 0]) {
    if (_closed) return;
    _session?.resizeTerminal(width, height, pixelWidth, pixelHeight);
  }

  @override
  Future<void> get done => _doneCompleter?.future ?? Future<void>.value();

  @override
  Object? get failure => _failure;

  @override
  String? get authBanner => _authBanner;

  @override
  String? get remoteVersion => _client.remoteVersion;

  @override
  bool get isClosed => _closed;

  @override
  Future<void> close() async {
    if (_closed) {
      await _doneCompleter?.future;
      return;
    }
    _closed = true;
    try {
      _session?.close();
    } catch (_) {}
    try {
      await _client.close();
    } catch (_) {}
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    await _stdoutController.close();
    await _stderrController.close();
    if (_doneCompleter != null && !_doneCompleter!.isCompleted) {
      _doneCompleter!.complete();
    }
  }
}
