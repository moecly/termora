import 'package:flutter/material.dart';

import '../data/known_hosts_repository.dart';
import '../data/models.dart';
import '../ui/common/prompts.dart';

/// Verifies SSH host public keys against remembered ones, prompting the user on
/// first contact and on change.
///
/// All prompts are serialized through a shared [PromptQueue]; only cancel or
/// overwrite are offered on a key change (never a one-time "ignore").
class HostKeyVerifier {
  HostKeyVerifier({
    required this.knownHosts,
    required this.navigatorKey,
    PromptQueue? queue,
    this.decide,
  }) : _queue = queue ?? PromptQueue();

  final KnownHostsRepository knownHosts;
  final GlobalKey<NavigatorState> navigatorKey;
  final PromptQueue _queue;

  /// Optional non-interactive decision callback. When set (integration tests
  /// only) it replaces the dialogs entirely; production passes null.
  final Future<bool> Function(String host, int port, String keyType, String fingerprint)? decide;

  /// [fingerprint] is the OpenSSH-style `SHA256:<base64>` string.
  Future<bool> verify(
    String host,
    int port,
    String keyType,
    String fingerprint,
  ) {
    return _queue.run(() => _verify(host, port, keyType, fingerprint));
  }

  Future<bool> _verify(
    String host,
    int port,
    String keyType,
    String fingerprint,
  ) async {
    final decision = decide;
    if (decision != null) {
      final trusted = await decision(host, port, keyType, fingerprint);
      if (trusted) {
        await _remember(host, port, keyType, fingerprint);
      }
      return trusted;
    }
    final previous = knownHosts.lookup(host, port);
    if (previous == null) {
      final trusted = await showTermoraDialog<bool>(
        navigatorKey,
        builder: (context) => _HostKeyDialog(
          title: '首次连接此服务器',
          host: host,
          port: port,
          keyType: keyType,
          primaryFingerprint: fingerprint,
          explanation: '请核对指纹是否与服务器一致。',
          confirmLabel: '信任并继续',
        ),
      );
      if (trusted != true) return false;
      await _remember(host, port, keyType, fingerprint);
      return true;
    }

    if (previous.fingerprint == fingerprint) return true;

    final trusted = await showTermoraDialog<bool>(
      navigatorKey,
      builder: (context) => _HostKeyDialog(
        title: '⚠ 主机密钥已变更',
        host: host,
        port: port,
        keyType: keyType,
        primaryFingerprint: fingerprint,
        previousFingerprint: previous.fingerprint,
        explanation: '这可能意味着中间人攻击，或服务器被重装/更换了密钥。',
        confirmLabel: '仍要信任新密钥',
      ),
    );
    if (trusted != true) return false;
    await _remember(host, port, keyType, fingerprint);
    return true;
  }

  Future<void> _remember(String host, int port, String keyType, String fingerprint) {
    return knownHosts.remember(
      KnownHost(
        host: host,
        port: port,
        keyType: keyType,
        fingerprint: fingerprint,
        addedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class _HostKeyDialog extends StatelessWidget {
  const _HostKeyDialog({
    required this.title,
    required this.host,
    required this.port,
    required this.keyType,
    required this.primaryFingerprint,
    required this.explanation,
    required this.confirmLabel,
    this.previousFingerprint,
  });

  final String title;
  final String host;
  final int port;
  final String keyType;
  final String primaryFingerprint;
  final String? previousFingerprint;
  final String explanation;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
        );
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$host:$port', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (previousFingerprint != null) ...[
              const _Label('已保存'),
              Text(previousFingerprint!, style: mono),
              const SizedBox(height: 8),
              const _Label('本次收到'),
            ] else
              const _Label('密钥类型'),
            Text(keyType, style: mono),
            const SizedBox(height: 8),
            if (previousFingerprint == null) const _Label('指纹'),
            SelectableText(primaryFingerprint, style: mono),
            const SizedBox(height: 12),
            Text(explanation, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
