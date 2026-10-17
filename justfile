default:
    @just --list

# Enter the Nix development shell.
develop:
    nix develop

# Enter the shell that also ships the Android emulator + x86_64 system image.
emulator-shell:
    nix develop .#android-emulator

# Check the Nix flake.
check:
    nix flake check

# Update flake inputs.
update:
    nix flake update

# Show flake outputs.
show:
    nix flake show

# Format Nix files.
fmt:
    nix fmt

# Fetch Dart/Flutter dependencies.
deps:
    flutter pub get

# Static analysis.
analyze:
    flutter analyze --fatal-infos

# Unit + widget tests (integration tests are excluded).
test:
    flutter test --exclude-tags integration

# Integration tests: requires a local sshd (see sshd-up).
test-integration:
    flutter test --tags integration

# Start the throwaway local sshd used by integration tests (port 2222).
sshd-up:
    tool/local-sshd.sh up

# Stop the throwaway local sshd.
sshd-down:
    tool/local-sshd.sh down

# Run on the Linux desktop.
run-linux:
    flutter run -d linux

# Build the Linux desktop bundle.
build-linux:
    flutter build linux --release

# Build a debug APK.
build-apk:
    flutter build apk --debug

# Install the debug APK on the connected device/emulator.
apk-install:
    flutter install --debug

# Install the debug APK on the connected device/emulator and verify it launches.
# Fails with recent logcat when the app does not stay running.
adb-test:
    #!/usr/bin/env bash
    set -euo pipefail
    device="$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')"
    if [ -z "$device" ]; then
        echo "error: no adb device in 'device' state." >&2
        echo "connect a device over USB (enable USB debugging) or run 'just emulator-shell' and start one." >&2
        adb devices >&2
        exit 1
    fi
    echo "==> device: $device"
    flutter build apk --debug
    adb -s "$device" logcat -c
    adb -s "$device" install -r build/app/outputs/flutter-apk/app-debug.apk
    adb -s "$device" shell am start -n com.termora.termora/.MainActivity
    sleep 5
    if [ -n "$(adb -s "$device" shell pidof com.termora.termora | tr -d '\r')" ]; then
        echo "==> termora is running on $device"
    else
        echo "error: termora did not stay running; recent logcat:" >&2
        adb -s "$device" logcat -d -t 200 >&2
        exit 1
    fi
