import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Result of an export operation. Null (returned by [BackupIo.export]) means
/// the user cancelled.
class BackupExportResult {
  const BackupExportResult({required this.shared, this.path});

  /// True when the file was handed to the OS share sheet (Android).
  final bool shared;

  /// Saved path on desktop, or the temporary path that was shared on Android.
  final String? path;
}

class BackupIo {
  static const XTypeGroup _jsonGroup = XTypeGroup(
    label: 'Termora 备份',
    extensions: ['json'],
  );

  static bool get _isDesktop {
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.windows ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };
  }

  /// Exports [json]. On desktop uses a save dialog; on Android (which does not
  /// support `getSaveLocation`) writes a temp file and opens the share sheet.
  /// Returns null when the user cancels the save dialog.
  static Future<BackupExportResult?> export(String json) async {
    final stamp = _timestamp();
    final name = 'termora-backup-$stamp.json';
    if (_isDesktop) {
      final location = await getSaveLocation(
        suggestedName: name,
        acceptedTypeGroups: const [_jsonGroup],
      );
      if (location == null) return null;
      await File(location.path).writeAsString(json);
      return BackupExportResult(shared: false, path: location.path);
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Termora 备份',
        text: 'Termora 服务器配置备份',
      ),
    );
    return BackupExportResult(shared: true, path: file.path);
  }

  /// Returns the picked file's text, or null if the user cancelled.
  static Future<String?> pickImportText() async {
    final file = await openFile(acceptedTypeGroups: const [_jsonGroup]);
    if (file == null) return null;
    return file.readAsString();
  }

  static String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}';
  }
}
