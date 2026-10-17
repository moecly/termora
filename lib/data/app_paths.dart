import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves and owns the on-disk locations used by the app.
///
/// Constructed exactly once in `main()` via [AppPaths.resolve].
class AppPaths {
  AppPaths._(this.supportDir);

  /// Root application support directory.
  final Directory supportDir;

  static Future<AppPaths> resolve() async {
    final dir = await getApplicationSupportDirectory();
    await Directory(dir.path).create(recursive: true);
    return AppPaths._(dir);
  }

  File get serversFile => File('${supportDir.path}/servers.json');
  File get settingsFile => File('${supportDir.path}/settings.json');
  File get knownHostsFile => File('${supportDir.path}/known_hosts.json');
  File get fallbackSecretsFile => File('${supportDir.path}/secrets.json');
  Directory get logsDir => Directory('${supportDir.path}/logs');
}
