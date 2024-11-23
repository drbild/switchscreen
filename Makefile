PROGRAM = switchscreen
VERSION = 1.0
RELEASE = 1

DISTNAME = $(PROGRAM)-$(VERSION)
DISTDIR  = $(DISTNAME)
DISTFILE = $(DISTNAME).tar.gz

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

RPMBUILD_DIR = rpmbuild

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
	rm -f $(DISTFILE)
	rm -rf $(RPMBUILD_DIR)

dist:
	mkdir -p $(DISTDIR)
	cp $(SRC) $(SERVICE_UNIT) Makefile $(DISTDIR)/
	tar -czf $(DISTFILE) $(DISTDIR)
	rm -rf $(DISTDIR)

rpm: dist
	mkdir -p $(RPMBUILD_DIR)/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	cp $(DISTFILE) $(RPMBUILD_DIR)/SOURCES/
	rpmbuild --define "_topdir $(PWD)/$(RPMBUILD_DIR)" -ta $(DISTFILE)


install_rpm: rpm
	sudo zypper install --allow-unsigned-rpm $(RPMBUILD_DIR)/RPMS/x86_64/$(TARGET)-$(VERSION)-$(RELEASE).x86_64.rpm
