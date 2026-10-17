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
      var effectivePassword = password;
      if (effectivePassword == null || effectivePassword.isEmpty) {
        effectivePassword = await prompts.run(
          () => promptPassword(
            navigatorKey,
            title: '需要密码',
            message: '${server.username}@${server.host}:${server.port}',
          ),
        );
        if (effectivePassword == null) {
          throw '已取消输入密码';
        }
      }
      auth = AuthConfig(method: AuthMethod.password, password: effectivePassword);

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
      }
      auth = AuthConfig(
        method: AuthMethod.privateKey,
        privateKeyPem: privateKey,
        passphrase: passphrase,
      );
  }

  final timeout = Duration(seconds: settings.connectTimeoutSeconds);
  final connection = await DartSshConnection.connect(
    server: server,
    auth: auth,
    verifier: verifier,
    connectTimeout: timeout,
    keepAliveSeconds: settings.keepAliveSeconds,
    passwordRequest: () => prompts.run(
      () => promptPassword(
        navigatorKey,
        title: '需要密码',
        message: '${server.username}@${server.host}:${server.port}',
      ),
    ),
    userInfoRequest: (request) => prompts.run(
      () => promptUserInfo(
        navigatorKey,
        title: request.name.isEmpty ? '需要验证' : request.name,
        message: request.instruction,
        prompts: [for (final p in request.prompts) p.promptText],
        echos: [for (final p in request.prompts) p.echo],
      ),
    ),
  );

  await connection.openShell(width: width, height: height);
  return connection;
}
