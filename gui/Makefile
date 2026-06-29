BUILD_DIR := build
BIN := $(BUILD_DIR)/psiphon-cli-gui
ROOT := ..
PREFIX ?= /usr/local
DESTDIR ?=

.PHONY: all help setup reconfigure bundle build run install package rpm rpm-offline clean distclean

.DEFAULT_GOAL := help

help:
	@echo "Psiphon CLI GUI — make targets"
	@echo ""
	@echo "  make setup        Configure Meson build directory ($(BUILD_DIR)/)"
	@echo "  make reconfigure  Re-run Meson setup with current options"
	@echo "  make bundle       Copy local server list into configs/ (no download)"
	@echo "  make build        Compile the GUI (bundles server list automatically)"
	@echo "  make run          Build and launch ./$(BIN)"
	@echo "  make install      Install to PREFIX ($(PREFIX))"
	@echo "  make package      Build and create ../dist/psiphon-cli-gui-*.tar.gz"
	@echo "  make rpm          Build Fedora/RHEL RPM (online: refreshes missing assets)"
	@echo "  make rpm-offline  Build RPM offline (requires npm run prepare:rpm first)"
	@echo "  make clean        Remove compiled objects"
	@echo "  make distclean    Remove $(BUILD_DIR)/ entirely"
	@echo ""
	@echo "Environment:"
	@echo "  PSIPHON_SERVER_LIST   Explicit server list file to bundle"
	@echo "  PSIPHON_CONFIG_DIR    Config dir to read remote_server_list from"
	@echo "  PREFIX                Install prefix (default: /usr/local)"
	@echo "  DESTDIR               Staging root for packaging"

setup:
	meson setup $(BUILD_DIR)

reconfigure:
	meson setup $(BUILD_DIR) --reconfigure

bundle:
	node $(ROOT)/scripts/bundle-server-list.js

build:
	@test -d $(BUILD_DIR) || meson setup $(BUILD_DIR)
	meson compile -C $(BUILD_DIR)

run: build
	./$(BIN)

install: build
	meson install -C $(BUILD_DIR) --destdir=$(DESTDIR)

package:
	bash $(ROOT)/scripts/package-gui.sh

rpm:
	bash $(ROOT)/scripts/build-gui-rpm.sh

rpm-offline:
	bash $(ROOT)/scripts/build-gui-rpm.sh --offline

clean:
	@if [ -d $(BUILD_DIR) ]; then meson compile -C $(BUILD_DIR) --clean; fi

distclean:
	rm -rf $(BUILD_DIR)

all: build
