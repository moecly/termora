#!/usr/bin/env bash
# Starts a throwaway sshd listening only on 127.0.0.1:2222, used by integration
# tests. It never touches ~/.ssh or any system config: AuthorizedKeysFile points
# at a dedicated key under /tmp.
#
# Runs in debug mode (`-d`): that lets an unprivileged user run sshd without root
# (no privilege separation, no login records) and serves exactly ONE connection,
# which is all the integration suite needs.
#
# When not running as root we also preload tool/pty_chown_shim.c, because this
# sandbox has no capabilities and its devpts hands pty slaves to a group that
# OpenSSH cannot chgrp to (see the comment in that file). Root does not need it.
set -euo pipefail
ROOT=/tmp/termora-sshd
PORT=2222
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# sshd refuses to run when invoked via a PATH lookup; resolve it to an absolute path.
SSHD="$(command -v sshd)"

up() {
  mkdir -p "$ROOT"
  [ -f "$ROOT/host_ed25519" ] || ssh-keygen -q -t ed25519 -N '' -f "$ROOT/host_ed25519"
  [ -f "$ROOT/client_ed25519" ] || ssh-keygen -q -t ed25519 -N '' -f "$ROOT/client_ed25519"
  cp "$ROOT/client_ed25519.pub" "$ROOT/authorized_keys"
  cat > "$ROOT/sshd_config" <<EOF
Port $PORT
ListenAddress 127.0.0.1
HostKey $ROOT/host_ed25519
PidFile $ROOT/sshd.pid
AuthorizedKeysFile $ROOT/authorized_keys
StrictModes no
PasswordAuthentication yes
PermitEmptyPasswords no
UsePAM no
UseDNS no
PrintMotd no
LogLevel INFO
Subsystem sftp internal-sftp
EOF

  if [ "$(id -u)" -ne 0 ]; then
    local shim="$ROOT/pty_chown_shim.so"
    if [ ! -f "$shim" ] || [ "$SCRIPT_DIR/pty_chown_shim.c" -nt "$shim" ]; then
      cc -O2 -shared -fPIC -o "$shim" "$SCRIPT_DIR/pty_chown_shim.c"
    fi
    export LD_PRELOAD="$shim"
  fi

  : > "$ROOT/sshd.log"
  setsid "$SSHD" -d -e -f "$ROOT/sshd_config" </dev/null >>"$ROOT/sshd.log" 2>&1 &
  echo $! > "$ROOT/sshd.pid"
  for _ in $(seq 1 50); do
    grep -q "Server listening" "$ROOT/sshd.log" 2>/dev/null && break
    sleep 0.1
  done
  echo "sshd listening on 127.0.0.1:$PORT (log: $ROOT/sshd.log)"
}

down() {
  if [ -f "$ROOT/sshd.pid" ]; then
    kill "$(cat "$ROOT/sshd.pid")" 2>/dev/null || true
    rm -f "$ROOT/sshd.pid"
  fi
  echo "sshd stopped"
}

case "${1:-}" in
  up) up ;;
  down) down ;;
  *) echo "usage: $0 {up|down}"; exit 2 ;;
esac
