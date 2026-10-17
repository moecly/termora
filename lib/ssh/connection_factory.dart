import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/secret_store.dart';
import '../data/settings_repository.dart';
import '../ui/common/prompts.dart';
import 'auth_config.dart';
import 'dart_ssh_connection.dart';
import 'host_key_verifier.dart';
import 'ssh_connection.dart';

/// Resolves the password for an SSH connection.
///
/// Returns [stored] unchanged when it is non-empty; otherwise prompts once and,
/// before returning, persists the entered value via [remember]. Returns null
/// only when the prompt is cancelled.
Future<String?> resolvePassword({
  required String? stored,
  required Future<String?> Function() prompt,
  required Future<void> Function(String value) remember,
}) async {
  if (stored != null && stored.isNotEmpty) return stored;
  final result = await prompt();
  if (result == null) return null;
  await remember(result);
  return result;
}

/// Builds a real, authenticated [SshConnection] with an open shell.
///
/// Reads stored secrets; when a required password/passphrase is missing it
/// prompts through [prompts] (shared with [HostKeyVerifier]).
Future<SshConnection> defaultSshConnector({
  required ServerConfig server,
  required int width,
  required int height,
  required SecretStore secretStore,
  required HostKeyVerifier verifier,
  required GlobalKey<NavigatorState> navigatorKey,
  required AppSettings settings,
  required PromptQueue prompts,
}) async {
  final password = await secretStore.read('password:${server.id}');
  final privateKey = await secretStore.read('privateKey:${server.id}');
  var passphrase = await secretStore.read('passphrase:${server.id}');

  AuthConfig auth;
  switch (server.authMethod) {
    case AuthMethod.password:
      // The password (stored or prompted) is supplied lazily through
      // [requestPassword] below; dartssh2 has no direct password parameter.
      auth = AuthConfig(method: AuthMethod.password, password: password);

    case AuthMethod.privateKey:
      if (privateKey == null || privateKey.isEmpty) {
        throw '此服务器未保存私钥，请先编辑服务器并导入私钥';
      }
      var needsPassphrase = false;
      try {
        needsPassphrase = SSHKeyPair.isEncryptedPem(privateKey);
      } on Object {
        throw '私钥格式无效，请先编辑服务器重新导入';
      }
      if (needsPassphrase && (passphrase == null || passphrase.isEmpty)) {
        passphrase = await prompts.run(
          () => promptPassword(
            navigatorKey,
            title: '需要私钥口令',
            message: '${server.username}@${server.host}:${server.port}',
          ),
        );
        if (passphrase == null) {
          throw '已取消输入私钥口令';
        }
        if (server.rememberPassphrase) {
          await secretStore.write('passphrase:${server.id}', passphrase);
        }
      }
      auth = AuthConfig(
        method: AuthMethod.privateKey,
        privateKeyPem: privateKey,
        passphrase: passphrase,
      );
  }

  /// Supplies the password for the `password` auth method: the stored secret
  /// when present, otherwise a single prompt (persisted when remembered).
  Future<String?> requestPassword() => resolvePassword(
        stored: auth.password,
        prompt: () => prompts.run(
          () => promptPassword(
            navigatorKey,
            title: '需要密码',
            message: '${server.username}@${server.host}:${server.port}',
          ),
        ),
        remember: (value) async {
          if (server.rememberPassword) {
            await secretStore.write('password:${server.id}', value);
          }
        },
      );

  /// Keyboard-interactive handler. A lone non-echo field is treated as the
  /// password, so a stored secret satisfies it without prompting.
  Future<List<String>?> requestUserInfo(SSHUserInfoRequest request) {
    final stored = auth.password;
    final singleSecret =
        request.prompts.length == 1 && request.prompts.single.echo == false;
    if (singleSecret && stored != null && stored.isNotEmpty) {
      return Future<List<String>?>.value(<String>[stored]);
    }
    return prompts.run(() async {
      final result = await promptUserInfo(
        navigatorKey,
        title: request.name.isEmpty ? '需要验证' : request.name,
        message: request.instruction,
        prompts: [for (final p in request.prompts) p.promptText],
        echos: [for (final p in request.prompts) p.echo],
      );
      if (result != null && singleSecret && server.rememberPassword) {
        await secretStore.write('password:${server.id}', result.single);
      }
      return result;
    });
  }

  final timeout = Duration(seconds: settings.connectTimeoutSeconds);
  final connection = await DartSshConnection.connect(
    server: server,
    auth: auth,
    verifier: verifier,
    connectTimeout: timeout,
    keepAliveSeconds: settings.keepAliveSeconds,
    passwordRequest: requestPassword,
    userInfoRequest: requestUserInfo,
  );

  await connection.openShell(width: width, height: height);
  return connection;
}
