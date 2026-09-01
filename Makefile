.PHONY: help build build-dual build-telex build-vni install reinstall test test-golden test-full clean verify setup-vi doctor enable-input

ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
IM_DIR := $(HOME)/Library/Input Methods

help:
	@echo "ToolVN — lệnh make"
	@echo ""
	@echo "  make build-dual     Build 2 IME: ToolVN-Telex.app + ToolVN-VNI.app"
	@echo "  make build          Alias của build-dual"
	@echo "  make build-telex    Chỉ build Telex"
	@echo "  make build-vni      Chỉ build VNI"
	@echo "  make setup-vi       Gỡ bộ gõ Việt Apple + cài 2 IME + Telex/VNI trên menu"
	@echo "  make install        Cài 2 bundle vào ~/Library/Input Methods/"
	@echo "  make enable-input Chỉ bật ToolVN trong nguồn nhập"
	@echo "  make doctor       Kiểm tra cài đặt / icon / đăng ký"
	@echo "  make reinstall    Gỡ bản cũ, build lại, cài lại + reload IM"
	@echo "  make test         Chạy toàn bộ test (golden + extended)"
	@echo "  make test-golden  Chỉ bộ golden"
	@echo "  make verify       Smoke test engine nhanh"
	@echo "  make clean        Xóa build/ và .build/"

build build-dual:
	@$(ROOT)Scripts/build-im.sh

build-telex:
	@TOOLVN_VARIANT=telex $(ROOT)Scripts/build-im.sh

build-vni:
	@TOOLVN_VARIANT=vni $(ROOT)Scripts/build-im.sh

install: build-dual
	@$(ROOT)Scripts/install.sh
	@$(ROOT)Scripts/enable-input-source.sh

setup-vi: build-dual
	@$(ROOT)Scripts/install.sh
	@$(ROOT)Scripts/setup-vietnamese-input.sh
	@$(ROOT)Scripts/reload-im.sh
	@$(ROOT)Scripts/doctor.sh

reinstall:
	@rm -rf "$(IM_DIR)/ToolVN.app" "$(IM_DIR)/ToolVN-Telex.app" "$(IM_DIR)/ToolVN-VNI.app"
	@$(MAKE) install
	@$(ROOT)Scripts/reload-im.sh

doctor:
	@$(ROOT)Scripts/doctor.sh

enable-input:
	@$(ROOT)Scripts/enable-input-source.sh

test test-full:
	@cd "$(ROOT)" && swift run toolvn-test

test-golden test-strict:
	@cd "$(ROOT)" && swift run toolvn-test --strict

verify:
	@cd "$(ROOT)" && swift run toolvn-verify

clean:
	@rm -rf "$(ROOT)build" "$(ROOT).build"
	@echo "Đã xóa build/ và .build/"
