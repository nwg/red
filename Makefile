ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
space := $(subst ,, )

RACKET_VERSION := 7.7

ifndef $(RACKET_DIST)
RACKET_DIST := /Applications/Racket v7.7
endif

fixspace = $(subst $(space),\ ,$(1))

RACKET_SHARE_PKGS := $(RACKET_DIST)/share/pkgs

RACO := $(RACKET_DIST)/bin/raco
RACO_ESC := $(call fixspace,$(RACO))

.DEFAULT_GOAL := all

# local cache stuff
pkgs_dir := $(ROOT_DIR)/pkg
catalog_dir := $(pkgs_dir)/catalog
local_pkgs := $(pkgs_dir)/local-modules
local_catalogs := $(catalog_dir)/local
pkgs_install := $(pkgs_dir)/install
pkgs_install_tgt := $(pkgs_install)/$(RACKET_VERSION)/pkgs
auto_dep_pkgname := red-dependencies
auto_dep_pkg := $(pkgs_install_tgt)/$(auto_dep_pkgname)
plt_config := $(pkgs_install_tgt)/config.rktd 

# server stuff
server_dir := $(ROOT_DIR)/server
server := $(server_dir)/server
server_iso := $(server_dir)/sample.iso8859-1
server_utf8 := $(server_dir)/sample.utf8

export PLTADDONDIR=$(pkgs_install)

.PHONY: all
all: $(local_catalogs) $(auto_dep_pkg) $(server)

make_catalog = racket -l- pkg/dirs-catalog "$(1)" "$(2)"

catalog: $(local_catalogs)

$(local_catalogs):
	$(call make_catalog,$(local_catalogs),$(local_pkgs))

$(plt_config):
	$(RACO_ESC) pkg config --set catalogs file:///$(local_catalogs) $(shell "$(RACO)" pkg config catalogs)

$(auto_dep_pkg): $(local_catalogs)/pkg
	$(RACO_ESC) pkg install --batch --auto $(auto_dep_pkgname) || /usr/bin/true
	touch $@

$(server): $(server_dir)/server.rkt $(server_iso)
	$(RACO_ESC) exe -o $@ $<

$(server_iso): $(server_utf8)
	iconv -f UTF-8 -t ISO_8859-1 <$< >$@

all_out := $(local_catalogs) $(server)

clean:
	rm -rf $(all_out)

