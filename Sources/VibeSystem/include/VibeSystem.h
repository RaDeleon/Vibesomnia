// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
#include <stdint.h>
#include <sys/types.h>
uint64_t vibe_process_stamp(pid_t pid, uid_t *uid);
void vibe_install_signals(void);
int vibe_interrupted(void);
int vibe_spawn_script(const char *interpreter, const char *script, const char *directory,
                      const char *event, const char *home, int output_fd, pid_t *pid);
