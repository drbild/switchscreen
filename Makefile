PROGRAM = switchscreen
VERSION = 1.0
RELEASE = 1

ARCH := $(shell uname -m)

BUILDDIR=$(CURDIR)/build

DISTNAME = $(PROGRAM)-$(VERSION)
DISTDIR  = $(BUILDDIR)/$(DISTNAME)
DISTFILE = $(BUILDDIR)/$(DISTNAME).tar.gz

prefix = /usr/local
exec_prefix = $(prefix)

bindir = $(exec_prefix)/bin
libdir = $(exec_prefix)/lib
unitdir = $(libdir)/systemd/system

INSTALL = install

INSTALL_PROGRAM = $(INSTALL) -c -m 0755
INSTALL_DATA    = $(INSTALL) -c -m 0644

CC ?= gcc
CFLAGS = -Wall -Wextra -O2 `pkg-config --cflags libinput libsystemd libudev`
LDFLAGS = `pkg-config --libs libinput libsystemd libudev`

SRC = switchscreen.c

UNIT = switchscreen.service
UNIT_SRC = switchscreen.service.in

RPMBUILD_DIR = $(CURDIR)/rpmbuild
RPM_SPEC = switchscreen.spec

all: $(PROGRAM) $(UNIT)

$(PROGRAM): $(SRC) | $(BUILDDIR)
	$(CC) $(CFLAGS) $< -o $(BUILDDIR)/$@ $(LDFLAGS)

$(UNIT): $(UNIT_SRC) | $(BUILDDIR)
	sed "s|@BINDIR@|$(bindir)|g; s|@PROGRAM@|$(PROGRAM)|g" $(UNIT_SRC) > $(BUILDDIR)/$(UNIT)

$(BUILDDIR):
	mkdir $(BUILDDIR)

install: $(PROGRAM) $(UNIT)
	$(INSTALL_PROGRAM) -D $(BUILDDIR)/$(PROGRAM) $(DESTDIR)$(bindir)/$(PROGRAM)
	$(INSTALL_DATA) -D $(BUILDDIR)/$(UNIT) $(DESTDIR)$(unitdir)/$(UNIT)

uninstall:
	rm -f $(DESTDIR)$(bindir)/$(PROGRAM)
	rm -f $(DESTDIR)$(unitdir)/$(SERVICE_UNIT)

clean:
	rm -rf $(BUILDDIR)
	rm -rf $(RPMBUILD_DIR)

dist: $(PROGRAM) $(UNIT)
	mkdir -p $(DISTDIR)
	cp README.md Makefile LICENSE $(SRC) $(UNIT_SRC) $(RPM_SPEC) $(DISTDIR)/
	tar -czf $(DISTFILE) -C $(BUILDDIR) $(DISTNAME)
	rm -rf $(DISTDIR)

rpm: dist
	mkdir -p $(RPMBUILD_DIR)/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	cp $(DISTFILE) $(RPMBUILD_DIR)/SOURCES/
	rpmbuild --define "_topdir $(RPMBUILD_DIR)" -ta $(DISTFILE)

install_rpm:
	sudo zypper --no-refresh install --allow-unsigned-rpm $(RPMBUILD_DIR)/RPMS/$(ARCH)/$(DISTNAME)-$(RELEASE).x86_64.rpm
