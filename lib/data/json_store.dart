import 'dart:convert';
import 'dart:io';

/// A tiny helper around a single JSON document stored in a file.
///
/// Reads tolerate a missing file (returns null) and never silently lose data:
/// a file that fails to parse is renamed to `<name>.corrupt-<millis>` and null
/// is returned.
class JsonStore {
  JsonStore(this.file);

  final File file;

  Future<Map<String, Object?>?> read() async {
    if (!await file.exists()) return null;
    String raw;
    try {
      raw = await file.readAsString();
    } on FileSystemException {
      return null;
    }
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return decoded;
      if (decoded is Map) return decoded.cast<String, Object?>();
      await _quarantine();
      return null;
    } on FormatException {
      await _quarantine();
      return null;
    }
  }

  /// Atomic write: write to `<path>.tmp`, flush to disk, then rename over the
  /// target. Same-directory rename is atomic on Android/Linux/macOS/Windows.
  Future<void> write(Map<String, Object?> data) async {
    final tmp = File('${file.path}.tmp');
    await file.parent.create(recursive: true);
    final handle = await tmp.open(mode: FileMode.write);
    try {
      await handle.writeString(jsonEncode(data));
      await handle.flush();
    } finally {
      await handle.close();
    }
    await tmp.rename(file.path);
  }

  Future<void> _quarantine() async {
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final base = file.path;
      await file.rename('$base.corrupt-$stamp');
    } on FileSystemException {
      // Best effort only.
    }
  }
}
