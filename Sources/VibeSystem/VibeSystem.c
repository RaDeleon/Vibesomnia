// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
#include "VibeSystem.h"
#include <libproc.h>
#include <signal.h>
#include <string.h>
static volatile sig_atomic_t interrupted = 0;
static void stop_signal(int signal) { interrupted = signal; }
void vibe_install_signals(void) {
    signal(SIGTERM, stop_signal); signal(SIGINT, stop_signal); signal(SIGHUP, stop_signal);
}
int vibe_interrupted(void) { return interrupted; }
uint64_t vibe_process_stamp(pid_t pid, uid_t *uid) {
    struct proc_bsdinfo info;
    memset(&info, 0, sizeof(info));
    if (proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, sizeof(info)) != sizeof(info)) return 0;
    if (uid) *uid = info.pbi_uid;
    return (info.pbi_start_tvsec << 20) | info.pbi_start_tvusec;
}
#include <spawn.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
int vibe_spawn_script(const char *interpreter, const char *script, const char *directory,
                      const char *event, const char *home, int output_fd, pid_t *pid) {
    posix_spawnattr_t attrs;
    posix_spawn_file_actions_t actions;
    posix_spawnattr_init(&attrs); posix_spawn_file_actions_init(&actions);
    posix_spawnattr_setflags(&attrs, POSIX_SPAWN_SETPGROUP);
    posix_spawnattr_setpgroup(&attrs, 0);
    posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", 0, 0);
    posix_spawn_file_actions_adddup2(&actions, output_fd, STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&actions, output_fd, STDERR_FILENO);
    posix_spawn_file_actions_addchdir_np(&actions, directory);
    char *event_env = NULL, *home_env = NULL, *dir_env = NULL;
    asprintf(&event_env, "VIBESOMNIA_EVENT=%s", event);
    asprintf(&home_env, "HOME=%s", home);
    asprintf(&dir_env, "VIBESOMNIA_ADDON_DIR=%s", directory);
    char *argv[] = {(char *)interpreter, (char *)script, NULL};
    char *env[] = {"PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
                   "LANG=en_US.UTF-8", home_env, event_env, dir_env, NULL};
    int result = posix_spawn(pid, interpreter, &actions, &attrs, argv, env);
    posix_spawn_file_actions_destroy(&actions); posix_spawnattr_destroy(&attrs);
    free(event_env); free(home_env); free(dir_env);
    return result;
}
