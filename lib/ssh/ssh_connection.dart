/// Abstraction over a live SSH shell connection.
///
/// Exists purely for testability: [TerminalSession] talks to this interface so
/// its state machine can be driven by a fake in unit tests.
abstract class SshConnection {
  /// Raw bytes coming back from the remote shell.
  Stream<List<int>> get stdout;

  /// Stderr stream, if the server sends any.
  Stream<List<int>> get stderr;

  /// Sends raw bytes to the remote shell.
  void write(List<int> data);

  /// Requests a terminal resize.
  void resize(int width, int height, [int pixelWidth = 0, int pixelHeight = 0]);

  /// Completes when the connection ends (clean shutdown or error). Never
  /// throws.
  Future<void> get done;

  /// When [done] completes, holds the error that caused an unexpected
  /// disconnect, or null for a clean close.
  Object? get failure;

  /// The server's auth banner, if any.
  String? get authBanner;

  /// Identification string sent by the server, e.g. `SSH-2.0-OpenSSH_9.6`.
  String? get remoteVersion;

  bool get isClosed;

  Future<void> close();
}
