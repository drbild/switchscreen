// Copyright 2024 David R. Bild
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <libinput.h>
#include <libudev.h>

#include <linux/input-event-codes.h>

#include <systemd/sd-daemon.h>
#include <systemd/sd-journal.h>

const char *switch_screen_command = "/usr/bin/ddcutil setvcp 60 0x1b";

void switch_screen() {
  sd_journal_print(LOG_INFO, "Executing '%s' to switch screen.",
                   switch_screen_command);
  int rc = system(switch_screen_command);
  if (rc != 0) {
    sd_journal_print(LOG_ERR, "Failed to switch screens. %s returned %d",
                     switch_screen_command, rc);
  } else {
    sd_journal_print(LOG_INFO, "Successfully switched screen.");
  }
}

// Signal Handling
volatile sig_atomic_t running = 1;
int signal_pipe[2]; // Pipe for waking up poll on signals

void handle_signal(int sig) {
  if (sig == SIGHUP) {
    sd_journal_print(LOG_INFO, "Reloading switchscreen daemon...");
  } else {
    running = 0;
    sd_journal_print(LOG_INFO, "Shutting down switchscreen daemon...");
  }
  write(signal_pipe[1], "x", 1);
}

void setup_signals() {
  struct sigaction sa;
  sa.sa_handler = handle_signal;
  sa.sa_flags = 0;
  sigemptyset(&sa.sa_mask);
  sigaction(SIGINT, &sa, NULL);
  sigaction(SIGTERM, &sa, NULL);
  sigaction(SIGHUP, &sa, NULL);
}

// Libinput
static int open_restricted(const char *path, int flags, void *) {
  int fd = open(path, flags);
  if (fd < 0) {
    sd_journal_print(LOG_ERR, "Failed to open %s: %s\n", path, strerror(errno));
  }
  return fd;
}

static void close_restricted(int fd, void *) { close(fd); }

void log_libinput_to_sd_journal(struct libinput*,
                                enum libinput_log_priority priority,
                                const char *format,
                                va_list args) {
  int sd_priority;
  switch (priority) {
  case LIBINPUT_LOG_PRIORITY_ERROR:
    sd_priority = LOG_ERR;
    break;
  case LIBINPUT_LOG_PRIORITY_INFO:
    sd_priority = LOG_INFO;
    break;
  case LIBINPUT_LOG_PRIORITY_DEBUG:
    sd_priority = LOG_DEBUG;
    break;
  default:
    sd_priority = LOG_INFO;
    break;
  }

  sd_journal_printv(sd_priority, format, args);
}

static const struct libinput_interface libinput_interface = {
    .open_restricted = open_restricted, .close_restricted = close_restricted};

struct modifier_state {
  bool rightalt_pressed;
};

void process_events(struct libinput *li, struct modifier_state *state) {
  struct libinput_event *event;
  while ((event = libinput_get_event(li))) {
    if (libinput_event_get_type(event) == LIBINPUT_EVENT_KEYBOARD_KEY) {
      struct libinput_event_keyboard *kbd_event =
          libinput_event_get_keyboard_event(event);
      uint32_t key = libinput_event_keyboard_get_key(kbd_event);
      enum libinput_key_state key_state =
          libinput_event_keyboard_get_key_state(kbd_event);

      // Track state of right alt
      if (key == KEY_RIGHTALT) {
        state->rightalt_pressed = (key_state == LIBINPUT_KEY_STATE_PRESSED);
      }

      if (state->rightalt_pressed && key == KEY_F16 &&
          key_state == LIBINPUT_KEY_STATE_PRESSED) {
        switch_screen();
      }
    }
    libinput_event_destroy(event);
  }
}

int main() {
  int rc =1;

  if (pipe(signal_pipe) < 0) {
    sd_journal_print(LOG_ERR, "Failed to create signal pipe");
    goto out;
  }

  struct udev *udev = udev_new();
  if (!udev) {
    sd_journal_print(LOG_ERR, "Failed to create udev context");
    rc = 1;
    goto free_pipe;
  }
  sd_journal_print(LOG_INFO, "Created udev context");

  struct libinput *li =
      libinput_udev_create_context(&libinput_interface, NULL, udev);
  if (!li) {
    sd_journal_print(LOG_ERR, "Failed to create libinput context");
    goto free_udev;
  }
  sd_journal_print(LOG_INFO, "Created libinput context");

  libinput_log_set_handler(li, log_libinput_to_sd_journal);
  libinput_log_set_priority(li, LIBINPUT_LOG_PRIORITY_DEBUG);

  if (libinput_udev_assign_seat(li, "seat0") < 0) {
    sd_journal_print(LOG_ERR, "Failed to assign seat0");
    goto free_libinput;
  }
  sd_journal_print(LOG_INFO, "Assigned seat0");

  int fd = libinput_get_fd(li);
  if (fd < 0) {
    sd_journal_print(LOG_ERR, "Failed to get file descriptor from libinput");
    goto free_libinput;
  }
  sd_journal_print(LOG_INFO, "Polling on file descriptor %d", fd);

  struct pollfd fds = {.fd = fd, .events = POLLIN};

  setup_signals();

  sd_journal_print(LOG_INFO, "Daemon started");
  sd_notify(0, "READY=1");

  uint64_t watchdog_usec = 0;
  int watchdog_enabled = sd_watchdog_enabled(0, &watchdog_usec);
  int poll_timeout_msec = watchdog_enabled > 0 ? (int) watchdog_usec / 1000 / 2 : -1;

  struct modifier_state state = {false};

  while (running) {
    int poll_result = poll(&fds, 1, poll_timeout_msec);

    if (poll_result < 0) {
      if (running) {
        sd_journal_print(LOG_ERR, "Error during poll");
      }
      break;
    }

    if (poll_result > 0 && fds.revents & POLLIN) {
      libinput_dispatch(li);
      process_events(li, &state);
    }

    if (watchdog_enabled > 0) {
      sd_notify(0, "WATCHDOG=1");
    }
  }

  sd_notify(0, "STOPPING=1");
  rc = 0;

 free_libinput:
  libinput_unref(li);

 free_udev:
  udev_unref(udev);

 free_pipe:
  close(signal_pipe[0]);
  close(signal_pipe[1]);

 out:
  sd_journal_print(LOG_INFO, "Daemon exited: %d", rc);
  return rc;
}
