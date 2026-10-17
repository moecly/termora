import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/server_repository.dart';
import '../data/settings_repository.dart';
import 'session_status.dart';
import 'terminal_session.dart';

/// Owns the set of live [TerminalSession]s and tracks the active one.
class SessionManager extends ChangeNotifier {
  SessionManager({
    required this.servers,
    required this.settings,
    required this.connector,
  });

  final ServerRepository servers;
  final SettingsRepository settings;
  final SshConnector connector;

  final List<TerminalSession> _sessions = [];
  String? _activeSessionId;

  List<TerminalSession> get sessions => List.unmodifiable(_sessions);
  String? get activeSessionId => _activeSessionId;

  TerminalSession? sessionById(String id) {
    for (final s in _sessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  TerminalSession? get active {
    for (final s in _sessions) {
      if (s.id == _activeSessionId) return s;
    }
    return null;
  }

  /// Creates (or reuses) a session for [server].
  ///
  /// When [force] is false and a non-terminated session for the same server
  /// already exists, that session is activated and returned instead of opening
  /// a duplicate connection.
  Future<TerminalSession> connect(ServerConfig server, {bool force = false}) async {
    if (!force) {
      for (final session in _sessions) {
        if (session.server.id == server.id &&
            session.status != SessionStatus.disconnected &&
            session.status != SessionStatus.failed) {
          activate(session.id);
          return session;
        }
      }
    }
    final session = TerminalSession(
      server: server,
      connector: connector,
      maxLines: settings.settings.scrollbackLines,
      onStatusChanged: _onSessionStatusChanged,
    );
    _sessions.add(session);
    _activeSessionId = session.id;
    await servers.markConnected(server.id, DateTime.now().millisecondsSinceEpoch);
    notifyListeners();
    return session;
  }

  void _onSessionStatusChanged(TerminalSession session) {
    notifyListeners();
  }

  void activate(String sessionId) {
    if (_activeSessionId == sessionId) return;
    _activeSessionId = sessionId;
    notifyListeners();
  }

  void activateNext() {
    if (_sessions.isEmpty) return;
    final index = _sessions.indexWhere((s) => s.id == _activeSessionId);
    final next = _sessions[(index + 1) % _sessions.length];
    activate(next.id);
  }

  void activatePrevious() {
    if (_sessions.isEmpty) return;
    final index = _sessions.indexWhere((s) => s.id == _activeSessionId);
    final prev = _sessions[(index - 1 + _sessions.length) % _sessions.length];
    activate(prev.id);
  }

  Future<void> closeSession(String sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    final session = _sessions.removeAt(index);
    session.dispose();
    if (_activeSessionId == sessionId) {
      _activeSessionId = _sessions.isEmpty ? null : _sessions.last.id;
    }
    notifyListeners();
  }

  Future<void> disconnectAll() async {
    for (final session in List<TerminalSession>.of(_sessions)) {
      await session.disconnect(keepBuffer: true);
    }
  }

  @override
  void dispose() {
    for (final session in _sessions) {
      session.dispose();
    }
    _sessions.clear();
    super.dispose();
  }
}
