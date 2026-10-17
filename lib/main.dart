import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/app_paths.dart';
import 'data/json_store.dart';
import 'data/known_hosts_repository.dart';
import 'data/secret_store.dart';
import 'data/server_repository.dart';
import 'data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final paths = await AppPaths.resolve();
  final secretStore = await resolveSecretStore(paths);

  final servers = ServerRepository(JsonStore(paths.serversFile), secrets: secretStore);
  final knownHosts = KnownHostsRepository(JsonStore(paths.knownHostsFile));
  final settings = SettingsRepository(JsonStore(paths.settingsFile));

  await servers.load();
  await knownHosts.load();
  await settings.load();

  runApp(
    TermoraApp(
      secretStore: secretStore,
      servers: servers,
      knownHosts: knownHosts,
      settings: settings,
    ),
  );
}
