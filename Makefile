PROGRAM = switchscreen

prefix = /usr/local
exec_prefix = $(prefix)

bindir = $(exec_prefix)/bin
libdir = $(exec_prefix)/lib
systemddir = $(libdir)/systemd/system

INSTALL = install

INSTALL_PROGRAM = $(INSTALL) -c -m 0755
INSTALL_DATA    = $(INSTALL) -c -m 0644

CC ?= gcc
CFLAGS = -Wall -Wextra -O2 `pkg-config --cflags libinput libsystemd libudev`
LDFLAGS = `pkg-config --libs libinput libsystemd libudev`

SRC = switchscreen.c

SERVICE_UNIT = switchscreen.service

all: $(PROGRAM)

$(PROGRAM_NAME): $(SRC)
	$(CC) $(CFLAGS) -c $< -o $@ $(LDFLAGS)

install: $(PROGRAM)
	$(INSTALL_PROGRAM) -D $(PROGRAM) $(DESTDIR)$(bindir)/$(PROGRAM)
	$(INSTALL_DATA) -D $(SERVICE_UNIT) $(DESTDIR)$(systemddir)/$(SERVICE_UNIT)

uninstall:
	rm -f $(DESTDIR)$(bindir)/$(PROGRAM)
	rm -f $(DESTDIR)$(systemddir)/$(SERVICE_UNIT)

clean:
	rm -f $(PROGRAM)
