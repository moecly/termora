import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:xterm2/xterm.dart';

import '../data/models.dart';
import '../ssh/ssh_connection.dart';
import '../ssh/ssh_errors.dart';
import '../terminal/helper_key.dart';
import 'session_status.dart';

/// Signature of a function that opens an SSH shell connection.
typedef SshConnector = Future<SshConnection> Function({
  required ServerConfig server,
  required int width,
  required int height,
});

/// A single terminal session: owns the [Terminal] emulator, its controllers and
/// the underlying [SshConnection].
class TerminalSession extends ChangeNotifier {
  TerminalSession({
    required this.server,
    required this.connector,
    required this.maxLines,
    required this.onStatusChanged,
  }) : terminal = Terminal(maxLines: maxLines) {
    terminal.inputHandler = HelperKeyHandler(defaultInputHandler, modifiers);
  }

  final ServerConfig server;
  final SshConnector connector;
  final int maxLines;
  final void Function(TerminalSession) onStatusChanged;

  final Terminal terminal;
  final TerminalController terminalController = TerminalController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode(debugLabel: 'termora-terminal');
  final KeyModifiers modifiers = KeyModifiers();

  /// Anchor placed inside the terminal's `Actions` subtree, so clipboard
  /// intents routed through `Actions.invoke` resolve to the terminal's own
  /// handlers.
  final GlobalKey builderKey = GlobalKey(debugLabel: 'termora-viewport');

  final String id = newSessionId();

  SessionStatus _status = SessionStatus.disconnected;
  String? _errorMessage;
  String? _authBanner;
  String? _remoteTitle;

  SshConnection? _connection;
  StreamSubscription<String>? _subOut;
  StreamSubscription<String>? _subErr;
  bool _closed = false;
  bool _disposed = false;

  SessionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get authBanner => _authBanner;
  String? get remoteTitle => _remoteTitle;
  String? get remoteVersion => _connection?.remoteVersion;
  int get scrollbackLineCount => terminal.buffer.height;
  bool get isActive => _status == SessionStatus.connected;

  void _notify() {
    if (!_disposed) notifyListeners();
    onStatusChanged(this);
  }

  Future<void> start({required int width, required int height}) async {
    if (_status == SessionStatus.connected) return;
    _closed = false;
    _status = SessionStatus.connecting;
    _errorMessage = null;
    _notify();

    terminal.write('正在连接 ${server.username}@${server.host}:${server.port} …\r\n');

    terminal.onOutput = (data) {
      if (_closed) return;
      _connection?.write(utf8.encode(data));
    };
    terminal.onResize = (w, h, pw, ph) {
      if (_closed) return;
      _connection?.resize(w, h, pw, ph);
    };
    terminal.onTitleChange = (title) {
      _remoteTitle = title;
      _notify();
    };
    terminal.onBell = null;

    SshConnection connection;
    try {
      connection = await connector(server: server, width: width, height: height);
    } catch (error) {
      if (_disposed || _closed) return;
      _status = SessionStatus.failed;
      _errorMessage = describeSshError(error);
      _writeNotice(_errorMessage!);
      _notify();
      return;
    }

    if (_disposed || _closed) {
      await connection.close();
      return;
    }

    _connection = connection;
    _subOut = connection.stdout
        .cast<List<int>>()
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(terminal.write, onError: _onStreamError);
    _subErr = connection.stderr
        .cast<List<int>>()
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(terminal.write, onError: _onStreamError);
    _authBanner = connection.authBanner;

    _status = SessionStatus.connected;
    _notify();

    unawaited(
      connection.done.then((_) {
        if (_disposed || _closed || _status == SessionStatus.disconnected) return;
        _status = SessionStatus.disconnected;
        _errorMessage = describeSshError(connection.failure ?? '连接已断开');
        _writeNotice(_errorMessage!);
        _notify();
      }),
    );
  }

  Future<void> reconnect({required int width, required int height}) async {
    await disconnect(keepBuffer: true);
    terminal.write('\r\n—— 重新连接 ——\r\n');
    await start(width: width, height: height);
  }

  Future<void> disconnect({bool keepBuffer = true}) async {
    _closed = true;
    await _subOut?.cancel();
    await _subErr?.cancel();
    _subOut = null;
    _subErr = null;
    final connection = _connection;
    _connection = null;
    if (connection != null) {
      try {
        await connection.close();
      } catch (_) {
        // Ignore close errors.
      }
    }
    if (_status != SessionStatus.failed) _status = SessionStatus.disconnected;
    _notify();
  }

  /// Re-checks the underlying connection; used when the app is resumed (the OS
  /// may have silently killed a backgrounded socket).
  void refreshLiveness() {
    final connection = _connection;
    if (connection == null) return;
    if (connection.isClosed && _status == SessionStatus.connected) {
      _status = SessionStatus.disconnected;
      _errorMessage ??= '连接已断开';
      _notify();
    }
  }

  void _onStreamError(Object error, StackTrace stack) {
    if (_disposed || _closed) return;
    _errorMessage = describeSshError(error);
    _writeNotice(_errorMessage!);
    _notify();
  }

  void _writeNotice(String message) {
    terminal.write('\r\n\x1b[90m[termora] $message\x1b[0m\r\n');
  }

  @override
  void dispose() {
    _disposed = true;
    _closed = true;
    unawaited(_subOut?.cancel());
    unawaited(_subErr?.cancel());
    final connection = _connection;
    _connection = null;
    if (connection != null) {
      unawaited(connection.close().catchError((_) {}));
    }
    focusNode.dispose();
    scrollController.dispose();
    terminalController.dispose();
    modifiers.dispose();
    super.dispose();
  }
}
