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
build_dir := $(ROOT_DIR)/build

# server stuff
server_dir := $(ROOT_DIR)/src/libredserver
server_lib_build := $(build_dir)/libredserver
server_product := $(server_lib_build)/RedServer.framework

$(server_lib_build):
	mkdir -p $@

$(server_product): $(server_lib_build)
	cd $(server_lib_build) && cmake $(server_dir) && gmake
	touch $(server_product)

$(info $(server_product))

export PLTADDONDIR=$(pkgs_install)

.PHONY: all
all: $(local_catalogs) $(auto_dep_pkg) $(server_product)

make_catalog = racket -l- pkg/dirs-catalog "$(1)" "$(2)"

catalog: $(local_catalogs)

$(local_catalogs):
	$(call make_catalog,$(local_catalogs),$(local_pkgs))

$(plt_config):
	$(RACO_ESC) pkg config --set catalogs file:///$(local_catalogs) $(shell "$(RACO)" pkg config catalogs)

$(auto_dep_pkg): $(local_catalogs)/pkg
	$(RACO_ESC) pkg install --batch --auto $(auto_dep_pkgname) || /usr/bin/true
	touch $@

all_out := $(local_catalogs) $(build_dir)

clean:
	rm -rf $(all_out)



