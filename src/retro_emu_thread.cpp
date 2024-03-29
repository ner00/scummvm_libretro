// This is copyrighted software. More information is at the end of this file.

#include "retro_emu_thread.h"

#include <rthreads/rthreads.h>
#include <stdio.h>

#include "base/main.h"
#include "os.h"

static uintptr_t main_thread_id;
static sthread_t *emu_thread;
static slock_t *emu_mutex;
static slock_t *main_mutex;
static scond_t *emu_cv;
static scond_t *main_cv;
static bool emu_keep_waiting = true;
static bool main_keep_waiting = true;
static bool emu_has_exited = false;
static bool emu_thread_initialized = false;

static void retro_run_emulator(void *args) {
  static const char *argv[20] = {0};
  unsigned i;

  emu_has_exited = false;

  for (i = 0; i < cmd_params_num; i++)
    argv[i] = cmd_params[i];

  scummvm_main(cmd_params_num, argv);
  emu_has_exited = true;

  /* All done - switch back to the main
   * thread for the final time */
  slock_lock(main_mutex);
  main_keep_waiting = false;
  slock_unlock(main_mutex);

  slock_lock(emu_mutex);
  scond_signal(main_cv);
  slock_unlock(emu_mutex);
}

static void retro_switch_to_emu_thread() {
  slock_lock(emu_mutex);
  emu_keep_waiting = false;
  slock_unlock(emu_mutex);
  slock_lock(main_mutex);
  scond_signal(emu_cv);

  main_keep_waiting = true;
  while (main_keep_waiting) {
    scond_wait(main_cv, main_mutex);
  }
  slock_unlock(main_mutex);
}

static void retro_switch_to_main_thread() {
  slock_lock(main_mutex);
  main_keep_waiting = false;
  slock_unlock(main_mutex);
  slock_lock(emu_mutex);
  scond_signal(main_cv);

  emu_keep_waiting = true;
  while (emu_keep_waiting) {
    scond_wait(emu_cv, emu_mutex);
  }
  slock_unlock(emu_mutex);
}

void retro_switch_thread() {
  if (sthread_get_current_thread_id() == main_thread_id)
    retro_switch_to_emu_thread();
  else
    retro_switch_to_main_thread();
}

bool retro_init_emu_thread(void) {
  if (emu_thread_initialized)
    return true;

  main_thread_id = sthread_get_current_thread_id();

  main_mutex = slock_new();
  if (main_mutex == NULL)
    goto main_mutex_error;

  emu_mutex = slock_new();
  if (emu_mutex == NULL)
    goto emu_mutex_error;

  main_cv = scond_new();
  if (main_cv == NULL)
    goto main_cv_error;

  emu_cv = scond_new();
  if (emu_cv == NULL)
    goto emu_cv_error;

  emu_thread = sthread_create(retro_run_emulator, NULL);
  if (emu_thread == NULL)
    goto emu_thread_error;

  emu_thread_initialized = true;
  return true;

emu_thread_error:
  scond_free(emu_cv);
emu_cv_error:
  scond_free(main_cv);
main_cv_error:
  slock_free(emu_mutex);
emu_mutex_error:
  slock_free(main_mutex);
main_mutex_error:
  return false;
}

void retro_deinit_emu_thread() {
  if (!emu_thread_initialized)
    return;

  slock_free(main_mutex);
  slock_free(emu_mutex);
  scond_free(main_cv);
  scond_free(emu_cv);
  emu_thread_initialized = false;
}

bool retro_is_emu_thread_initialized() { return emu_thread_initialized; }

void retro_join_emu_thread() {
  static bool is_joined = false;
  if (is_joined)
    return;

  sthread_join(emu_thread);
  is_joined = true;
}

bool retro_emu_thread_exited() { return emu_has_exited; }

/*

Copyright (C) 2020 Nikos Chantziaras <realnc@gmail.com>

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <https://www.gnu.org/licenses/>.

*/
