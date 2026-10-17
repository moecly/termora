import 'dart:async';

import 'package:flutter/material.dart';

/// Serializes modal prompts so only one is shown at a time. Shared by the host
/// key verifier and the SSH auth prompts, because all of them push onto the
/// same navigator and SSH handshakes are serial.
class PromptQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }
}

/// Prompts for a single secret string (a password). Returns null if cancelled.
Future<String?> promptPassword(
  GlobalKey<NavigatorState> navigatorKey, {
  required String title,
  required String message,
}) {
  return showTermoraDialog<List<String>>(
    navigatorKey,
    builder: (context) => _TextPromptDialog(
      title: title,
      message: message,
      fields: const [ _FieldSpec(label: '密码', obscure: true) ],
    ),
  ).then((values) => values?.first);
}

/// Prompts for keyboard-interactive info. Returns null if cancelled.
///
/// When there is exactly one prompt and it echoes, a single text field is
/// shown; otherwise each prompt gets its own field (obscured when
/// `echo == false`).
Future<List<String>?> promptUserInfo(
  GlobalKey<NavigatorState> navigatorKey, {
  required String title,
  required String message,
  required List<String> prompts,
  required List<bool> echos,
}) {
  final fields = <_FieldSpec>[
    for (var i = 0; i < prompts.length; i++)
      _FieldSpec(label: prompts[i], obscure: !echos[i]),
  ];
  return showTermoraDialog<List<String>>(
    navigatorKey,
    builder: (context) => _TextPromptDialog(
      title: title,
      message: message,
      fields: fields,
    ),
  );
}

/// Shows a dialog through [navigatorKey]. Returns null if there is no navigator
/// or the user dismisses it.
Future<T?> showTermoraDialog<T>(
  GlobalKey<NavigatorState> navigatorKey, {
  required WidgetBuilder builder,
  bool barrierDismissible = false,
}) {
  final context = navigatorKey.currentState?.overlay?.context ??
      navigatorKey.currentContext;
  if (context == null) return Future<T?>.value(null);
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

class _FieldSpec {
  const _FieldSpec({required this.label, required this.obscure});
  final String label;
  final bool obscure;
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.message,
    required this.fields,
  });

  final String title;
  final String message;
  final List<_FieldSpec> fields;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final List<TextEditingController> _controllers = [
    for (final _ in widget.fields) TextEditingController(),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop([for (final c in _controllers) c.text]);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.message.isNotEmpty) ...[
            Text(widget.message),
            const SizedBox(height: 16),
          ],
          for (var i = 0; i < widget.fields.length; i++) ...[
            if (widget.fields.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.fields[i].label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            TextField(
              controller: _controllers[i],
              obscureText: widget.fields[i].obscure,
              autofocus: i == 0,
              decoration: InputDecoration(
                hintText: widget.fields.length == 1
                    ? (widget.fields[i].obscure ? '密码' : widget.fields[i].label)
                    : null,
              ),
              onSubmitted: i == widget.fields.length - 1 ? (_) => _submit() : null,
            ),
            if (i != widget.fields.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('确定')),
      ],
    );
  }
}
