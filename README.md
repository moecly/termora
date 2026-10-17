# Termora

一个快速、现代的 SSH 客户端（Flutter）。支持服务器管理、密码/私钥认证、主机密钥校验、真实终端仿真（vim/tmux/top 等全屏程序）、多会话与重连、主题与终端配色/字号、配置导入导出。

## 快速开始

```sh
nix develop          # 进入开发环境（Flutter + Android SDK + Linux 桌面依赖）
just deps            # flutter pub get
just run-linux       # 在 Linux 桌面运行
```

## 常用任务（`just --list`）

| 任务 | 说明 |
|---|---|
| `develop` | 进入 Nix 开发环境 |
| `emulator-shell` | 额外带 Android 模拟器与系统镜像的 shell |
| `check` / `update` / `show` / `fmt` | Nix flake 检查 / 更新 / 查看 / 格式化 |
| `deps` | `flutter pub get` |
| `analyze` | `flutter analyze --fatal-infos` |
| `test` | 单元 + Widget 测试（排除 `integration` 标签） |
| `test-integration` | 集成测试（需先 `just sshd-up`） |
| `sshd-up` / `sshd-down` | 起/停一次性本地 sshd（127.0.0.1:2222） |
| `run-linux` / `build-linux` | 运行 / 构建 Linux 桌面 |
| `build-apk` / `apk-install` | 构建 / 安装 Android debug APK |
| `adb-test` | 构建 → 安装 → 启动 debug APK，并用 adb 确认进程存活（失败时打印最近 logcat） |

## Linux 桌面

```sh
nix develop
just run-linux            # 或
just build-linux          # 产物：build/linux/x64/release/bundle/termora
```

## Android

```sh
nix develop
just build-apk            # 产物：build/app/outputs/flutter-apk/app-debug.apk
just apk-install          # 安装到已连接的设备/模拟器
```

devshell 的 Android SDK 是只读的 Nix store 路径，因此其中预先装好了 Flutter/AGP 会强制要求的那两个组件：NDK `28.2.13676358`（= Flutter 3.47.4 的 `flutter.ndkVersion`）与 CMake `3.22.1`（AGP 的默认版本，`path_provider_android → jni` 需要）。首次 `nix develop` 需要下载它们。

模拟器把宿主机映射为 `10.0.2.2`，因此连接本机服务请使用 `10.0.2.2:<port>` 而非 `127.0.0.1`。

## 集成测试

```sh
nix develop
just sshd-up              # 起本地 sshd（127.0.0.1:2222）
just test-integration     # 真实握手 / 密钥认证 / PTY / $TERM / stty size
just sshd-down
```

`just sshd-up` 以 `sshd -d`（debug 模式）前台运行，因此**只服务一次连接**：每跑一轮 `test-integration` 前请重新 `sshd-up`。未 root 时脚本会编译并 `LD_PRELOAD` `tool/pty_chown_shim.c`（见文件内注释）——在无 capability 的容器里，devpts 交出的 pty 属组无法被 sshd 改成 `tty`，而 OpenSSH 会把这个 `chown` 失败当成致命错误。

没有启动 sshd 时集成测试会自动跳过（不会让 `just test` 变红）。

## 数据与密钥位置

- 应用数据目录（`getApplicationSupportDirectory()`）：
  - `servers.json`：服务器与分组
  - `settings.json`：应用设置
  - `known_hosts.json`：已信任的主机密钥
  - `secrets.json`：**仅 Linux 桌面回退**时使用（权限 0600）
- 密码、私钥与私钥口令存储在系统密钥库：
  - Android/iOS/macOS/Windows：系统凭据存储（`flutter_secure_storage`）
  - Linux 桌面：`flutter_secure_storage_linux` 依赖已解锁的 Secret Service（gnome-keyring / kwallet）。若探测失败，会**仅限 Linux 桌面**回退到 `secrets.json` 并在控制台打印显式告警。

导出配置时默认**不包含**明文凭证；勾选后需二次确认。

## 未实现

SFTP 与端口转发尚未实现（`dartssh2` 已具备相应能力，后续接入无需改动现有架构）。
