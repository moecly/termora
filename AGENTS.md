# Repository Guidelines

## Project Overview
Termora — a fast, modern SSH client built with Flutter/Dart (`pubspec.yaml`, `name: termora`, version `1.0.0+1`). Features: server/group management, password & private-key auth, TOFU host-key verification, real terminal emulation (PTY `xterm-256color`, alt-screen; vim/tmux/top work), multi-session + reconnect, themes/fonts, config import/export.

- **UI text and docs are Simplified Chinese.** README/CHANGELOG are authoritative on intent.
- **Not implemented:** SFTP and port forwarding (`dartssh2` supports them; wiring them needs no architecture change).

## Architecture & Data Flow
Clean layered design, pure-Dart core (no Flutter deps below `ui/`), manual dependency injection.

```
main.dart  →  app/ (composition root, DI scope, MaterialApp)
                ↓
              ui/ (widgets)  →  session/ (ChangeNotifier state)
                                   ↓
                    ssh/ (transport, abstract SshConnection)  +  data/ (repos/models/persistence)
                    terminal/ (xterm2 wiring, themes, helper keys)  +  design/ (tokens, theme)
```

- **Bootstrap:** `lib/main.dart` `main()` → `AppPaths.resolve()` → `resolveSecretStore()` → construct `ServerRepository` / `KnownHostsRepository` / `SettingsRepository` → `await .load()` → `runApp(TermoraApp(...))`. No service locator; services passed by constructor.
- **DI seam:** `lib/app/app.dart` builds `ServicesScope` (an `InheritedNotifier<SessionManager>`) and a `_connect` closure injected as `SshConnector`; `defaultSshConnector` lives in `lib/ssh/connection_factory.dart`.
- **Connect flow:** `SessionManager.connect` → `TerminalSession.start` → injected `SshConnector` → `DartSshConnection` (dartssh2 `SSHClient`/`SSHSession`) → output `Stream` piped into an xterm2 `Terminal`.
- **Persistence:** in-memory-first `ChangeNotifier` repos write JSON atomically via `JsonStore` (`lib/data/json_store.dart`, tolerant reads, `.corrupt-<millis>` quarantine). Secrets go through the `SecretStore` abstraction.

## Key Directories
| Path | Purpose |
|---|---|
| `lib/main.dart`, `lib/app/` | Entry point, composition root, DI scope, root shell |
| `lib/data/` | Repositories, models, `JsonStore`, `SecretStore`, backup codec/IO, paths |
| `lib/ssh/` | `SshConnection` interface, dartssh2 impl, connection factory, host-key verifier, error mapping |
| `lib/session/` | `SessionManager` / `TerminalSession` (`ChangeNotifier`), status enum, Android hardware-key service |
| `lib/terminal/` | xterm2 handler wiring, themes, style cache, helper-key modifiers |
| `lib/ui/` | Flutter pages/widgets: `home/`, `servers/`, `terminal/`, `settings/`, `workspace/`, `common/` |
| `lib/design/` | Design tokens, `ThemeData` factory, shared presentational widgets |
| `test/` | Mirrors `lib/`; plus `test/integration/` |
| `tool/` | `local-sshd.sh` + `pty_chown_shim.c` for integration tests |
| `android/ linux/ macos/ windows/` | Platform runners (stock Flutter templates + small customizations) |

## Development Commands
All local and CI steps are wired through the `justfile` (run `just --list`). Requires the Nix devshell for Flutter/JDK/Android SDK.

```sh
nix develop            # or `just develop`; direnv auto-enters via .envrc (`use flake`)
just deps              # flutter pub get
just analyze           # flutter analyze --fatal-infos   (infos are errors)
just test              # flutter test --exclude-tags integration
just run-linux         # flutter run -d linux
just build-linux       # flutter build linux --release  → build/linux/x64/release/bundle/termora
just build-apk         # flutter build apk --debug
just adb-test          # build→install→launch APK, verify process stays alive
```

Integration tests (real handshake/key auth/PTY/`$TERM`/stty size) need a throwaway local sshd:

```sh
just sshd-up && just test-integration && just sshd-down
```

`just sshd-up` runs `sshd -d` on `127.0.0.1:2222` and serves **one** connection — restart it between runs. See `tool/local-sshd.sh`.

## Code Conventions & Common Patterns
Formatting/lint (see `analysis_options.yaml`, enforced by `--fatal-infos`):
- `flutter_lints` baseline + `strict-casts`, `strict-inference`, `strict-raw-types`.
- Extra rules: `always_declare_return_types`, `avoid_print`, `prefer_const_constructors`, `prefer_final_locals`, `unawaited_futures`, `use_super_parameters`.
- `dart format` conventions: files `snake_case.dart`, classes/enums `PascalCase`, constants `kCamelCase` (e.g. `kDefaultKeyMappings`, `kTerminalThemes`).

State & async:
- **No Provider/Riverpod/Bloc.** Services and sessions are `ChangeNotifier`s consumed via `ListenableBuilder`; local widget state uses `setState`. Access shared services through `ServicesScope`.
- Prefer `Future`/`Stream`; `unawaited_futures` is on, so explicitly `unawaited(...)` intentional fire-and-forget.
- Keep `data/` and `ssh/` logic pure-Dart and constructor-injected so it stays unit-testable without a widget tree.

Error handling:
- No Result/Either type. `describeSshError` (`lib/ssh/ssh_errors.dart`) maps `dartssh2`/`dart:io` exceptions to Chinese user-facing messages. Avoid `print` in app code.
- Host-key policy is TOFU via `HostKeyVerifier` (`lib/ssh/host_key_verifier.dart`); key changes are rejected by default. Dialog prompts are serialized with `PromptQueue` (`lib/ui/common/prompts.dart`).
- Never log credentials. Secrets live in `SecretStore`: OS credential store (Android/iOS/macOS/Windows) or Linux Secret Service; Linux desktop falls back to a `0600` `secrets.json` with an explicit console warning. Exports exclude plaintext credentials by default.

Testability seams to reuse: abstract `SshConnection`, `HostKeyVerifier.decide()`, injectable `SshConnector`, `SecretStore` implementable in-memory.

## Important Files
- `lib/main.dart` — entry point.
- `lib/app/app.dart` — composition root, `ServicesScope`, `MaterialApp`.
- `lib/data/json_store.dart` — atomic tolerant JSON persistence.
- `lib/data/models.dart` — `ServerConfig`, `ServerGroup`, `KnownHost`, `AuthMethod`, ID generators (`srv_`/`grp_`/`ses_`).
- `lib/ssh/connection_factory.dart`, `lib/ssh/dart_ssh_connection.dart` — transport layer.
- `lib/session/terminal_session.dart` — owns xterm2 `Terminal` + `SshConnection`.
- `lib/terminal/terminal_viewport.dart` — sole `TerminalView` instantiation (clipboard/pinch-zoom/shortcuts).
- `pubspec.yaml`, `analysis_options.yaml`, `dart_test.yaml`, `flake.nix`, `justfile`, `.github/workflows/ci.yml`.

Data locations (`getApplicationSupportDirectory()`): `servers.json`, `settings.json`, `known_hosts.json`, and Linux-only fallback `secrets.json`.

## Runtime/Tooling Preferences
- **Runtime:** Flutter/Dart. Dart SDK constraint `^3.11.0`; lockfile resolves `dart >=3.13.0 <4.0.0`, `flutter >=3.47.0`. Android NDK `28.2.13676358`, CMake `3.22.1` (pinned in `flake.nix`; the Nix-store SDK is read-only, so `android.builder.sdkDownload=false`).
- **Package manager:** `flutter pub` (no npm/Bun). Task runner: `just`. Dev environment: Nix flake (`flake.nix`, `flake.lock`) with direnv (`.envrc`).
- Prefer the Nix devshell over host toolchains; CI uses the same `just` tasks, so a green local run equals a green CI run.

## Testing & QA
- Frameworks: `flutter_test` (+ `flutter_lints`). Tests mirror `lib/` by directory; ~1600 lines across 16 files.
  - Unit: `test/data/`, `test/session/`, `test/ssh/`, `test/terminal/`.
  - Widget: `test/app/`, `test/ui/`.
  - Integration: `test/integration/ssh_e2e_test.dart` (tagged `integration`).
- `dart_test.yaml` declares the `integration` tag; these tests self-skip when the sshd fixture is absent, so plain `flutter test` stays green. `just test` excludes them; `just test-integration` runs only them.
- Conventions: `group`/`test` naming; hand-written in-memory fakes implementing real interfaces (e.g. `_MemorySecretStore`) — widget tests must avoid real `dart:io` awaits (fake-async deadlock). Use temp dirs for persistence tests.
- No coverage threshold is configured. Verification standard: run `just analyze` + `just test`, and exercise the changed surface (`just run-linux` / `just adb-test`); run `just test-integration` when touching SSH/PTY behavior.
- CI (`.github/workflows/ci.yml`): `test` job = analyze + unit/widget + real-sshd integration; `build` job = Linux bundle + Android APK, tag push `v*` publishes a GitHub Release.
