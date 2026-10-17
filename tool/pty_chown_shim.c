/*
 * Sandbox-only helper for tool/local-sshd.sh.
 *
 * Running sshd as an unprivileged user inside a container without any Linux
 * capabilities makes pty setup impossible: devpts in this environment hands the
 * pty slave to group 65534 while OpenSSH tries to chgrp it to the "tty" group
 * (gid 3). That chown fails with EINVAL and OpenSSH treats every errno except
 * EROFS as fatal (sshpty.c: pty_setowner), so the session dies right after the
 * pty is allocated.
 *
 * This shim makes ownership changes on devpts nodes report success, which is
 * harmless here: the pty slave is already owned by the connecting user (mode
 * 0620) and the code under test reaches the pty through sshd's file
 * descriptors, never the path. It is loaded into sshd only, never into Termora.
 *
 * Build:  cc -shared -fPIC -o pty_chown_shim.so pty_chown_shim.c
 * Use:    LD_PRELOAD=$PWD/pty_chown_shim.so sshd -d -e -f sshd_config
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stddef.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

static int is_pts_path(const char *path) {
  return path != NULL && strncmp(path, "/dev/pts/", 9) == 0;
}

static int is_pts_fd(int fd) {
  char link[64];
  char proc[64];
  ssize_t n;

  if (fd < 0) return 0;
  /* /proc/self/fd/<fd> -> /dev/pts/N */
  proc[0] = '\0';
  {
    /* tiny snprintf to avoid pulling in stdio */
    const char *pre = "/proc/self/fd/";
    size_t i = 0;
    while (pre[i] != '\0' && i < sizeof(proc) - 12) {
      proc[i] = pre[i];
      i++;
    }
    if (fd >= 100) proc[i++] = (char)('0' + (fd / 100) % 10);
    if (fd >= 10) proc[i++] = (char)('0' + (fd / 10) % 10);
    proc[i++] = (char)('0' + fd % 10);
    proc[i] = '\0';
  }
  n = readlink(proc, link, sizeof(link) - 1);
  if (n <= 0) return 0;
  link[n] = '\0';
  return strncmp(link, "/dev/pts/", 9) == 0;
}

int chown(const char *path, unsigned int owner, unsigned int group) {
  static int (*real)(const char *, unsigned int, unsigned int);
  if (!real) real = dlsym(RTLD_NEXT, "chown");
  if (is_pts_path(path)) return 0;
  return real(path, owner, group);
}

int fchown(int fd, unsigned int owner, unsigned int group) {
  static int (*real)(int, unsigned int, unsigned int);
  if (!real) real = dlsym(RTLD_NEXT, "fchown");
  if (is_pts_fd(fd)) return 0;
  return real(fd, owner, group);
}

int fchownat(int dirfd, const char *path, unsigned int owner, unsigned int group,
             int flags) {
  static int (*real)(int, const char *, unsigned int, unsigned int, int);
  if (!real) real = dlsym(RTLD_NEXT, "fchownat");
  if (is_pts_path(path) || is_pts_fd(dirfd)) return 0;
  return real(dirfd, path, owner, group, flags);
}
