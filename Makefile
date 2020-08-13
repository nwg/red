RACKET_VERSION := 7.8
RACKET_INPLACE := third-party/racket/racket/
INPLACE_LIB_DIR := $(RACKET_INPLACE)lib/
INPLACE_INCLUDE_DIR := $(RACKET_INPLACE)include/
RACKET_INPLACE_FRAMEWORK := $(INPLACE_LIB_DIR)Racket.framework
INSTALL_DIR := third-party/install/
INSTALL_INCLUDE_DIR := $(INSTALL_DIR)include/
INSTALL_LIB_DIR := $(INSTALL_DIR)lib/
INSTALL_FRAMEWORK_DIR := $(INSTALL_DIR)Frameworks/
RACKET_FRAMEWORK := $(INSTALL_FRAMEWORK_DIR)Racket.framework
RACKET_UNPATCHED_FRAMEWORK := $(INSTALL_FRAMEWORK_DIR)Racket-unpatched.framework

REDLIB_DIR := src/libred/
REDLIB_BUILD := $(REDLIB_DIR)build/
REDLIB_FRAMEWORK := $(REDLIB_BUILD)RedLib.framework

.PHONY: all
all: install

$(RACKET_INPLACE_FRAMEWORK):
	cd third-party/racket && $(MAKE) cs RACKETCS_SUFFIX=""

$(RACKET_FRAMEWORK): $(RACKET_INPLACE_FRAMEWORK)
	cp -R $(RACKET_INPLACE_FRAMEWORK) $(RACKET_FRAMEWORK)
	cd $(RACKET_FRAMEWORK)/Versions && ln -s $(RACKET_VERSION)_CS Current
	cd $(RACKET_FRAMEWORK) && ln -s Versions/Current/Resources Resources
	cd $(RACKET_FRAMEWORK) && ln -s Versions/Current/Racket
	mkdir -p $(RACKET_FRAMEWORK)/Versions/Current/Resources
	cp third-party/Racket-Info.plist $(RACKET_FRAMEWORK)/Versions/Current/Resources/Info.plist

$(INSTALL_LIB_DIR) $(INSTALL_FRAMEWORK_DIR) $(INSTALL_INCLUDE_DIR) \
	$(REDLIB_BUILD):
	mkdir -p $@

RACKET_HEADERS := chezscheme.h racketcs.h racketcsboot.h
RACKET_HEADERS_DESTS := $(foreach h,$(RACKET_HEADERS),$(INSTALL_INCLUDE_DIR)$(h))

$(INSTALL_INCLUDE_DIR)%.h: $(INPLACE_INCLUDE_DIR)%.h
	cp $< $@

$(REDLIB_FRAMEWORK): $(REDLIB_BUILD) $(REDLIB_DIR)/CMakeLists.txt $(RACKET_HEADERS_DESTS)
	cd $(REDLIB_BUILD) && cmake .. && $(MAKE)

.PHONY: install
install: $(INSTALL_INCLUDE_DIR) $(INSTALL_LIB_DIR) $(INSTALL_FRAMEWORK_DIR) $(RACKET_FRAMEWORK) \
	$(REDLIB_FRAMEWORK)
