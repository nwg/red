ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
space := $(subst ,, )

RACKET_VERSION := 7.7

ifndef $(RACKET_DIST)
RACKET_DIST := /Applications/Racket v7.7
endif

fixspace = $(subst $(space),\ ,$(1))

RACKET_LIB := $(ROOT_DIR)/third-party

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
install_dir := $(ROOT_DIR)/build/install
install_lib_dir := $(install_dir)/lib

# server stuff
red_server_framework := RedServer.framework
server_dir := $(ROOT_DIR)/src/libredserver
server_lib_build := $(build_dir)/libredserver
server_result := $(server_lib_build)/RedServer.framework
server_install_dest := $(install_dir)/lib/RedServer.framework

# racket stuff
racket_framework_src := $(RACKET_LIB)/Racket.framework
racket_framework_dest := $(install_lib_dir)/Racket.framework

export PLTADDONDIR=$(pkgs_install)

.PHONY: all
all: $(local_catalogs) $(auto_dep_pkg) $(server_install_dest) $(racket_framework_dest)

$(racket_framework_dest): $(racket_framework) | $(install_lib_dir)
	cp -a "$(racket_framework_src)" "$@"
	touch "$@"

$(server_install_dest): $(server_result) | $(install_lib_dir)
	cp -a $< $@
	touch $@

$(server_lib_build) $(install_dir) | $(install_lib_dir):
	mkdir -p $@

$(server_result): $(server_lib_build)
	echo "$(server_result) needs updating (looking at $(server_lib_build))"
	cd $(server_lib_build) && cmake $(server_dir) && gmake
	touch $@

$(info server_lib_build=$(server_lib_build) and server_result=$(server_result))

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



