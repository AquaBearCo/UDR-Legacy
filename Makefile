# =====================================================
# UDR Master Makefile (root-anchored, quiet by default)
# =====================================================
#   - root_dir uses abspath for reliability
#   - Separate dist trees: UDT and UDR
#   - Auto-generates version.h
#   - Static/shared linking auto-detect
#   - Quiet by default; full logs with DEBUG=1
# =====================================================

# ------------------------------
# 10. Path definitions
# ------------------------------
root_dir   := $(abspath $(CURDIR)/../..)   # e.g., /home/ubuntu/undercurrent
src_dir    := $(root_dir)/src
udt_root   := $(src_dir)/udt
udr_root   := $(src_dir)/udr

dist_udt   := $(udt_root)/dist              # built libudt*.{a,so}
dist_udr   := $(udr_root)/dist              # built udr + staged libs
bin_dir    := $(dist_udr)/bin
lib_dir    := $(dist_udr)/lib
src_udr    := $(udr_root)/src
version_h  := $(src_udr)/version.h

app_udr    := udr

# ------------------------------
# 20. Build configuration
# ------------------------------
CXX        = g++
OS         ?= LINUX
ARCH       ?= AMD64
DEBUG      ?= 0      # 0 = quiet, 1 = verbose build output

INC_PATHS  := $(shell find $(src_udr) -type d 2>/dev/null)
CXXFLAGS   := -Wall -D$(OS) -finline-functions -g -I$(udt_root)/src $(addprefix -I,$(INC_PATHS))

LDFLAGS_STATIC := -ludt -lssl -lcrypto -lz -lpthread -lm -static-libstdc++
LDFLAGS_SHARED := -ludt -lssl -lcrypto -lz -lpthread -lm -lstdc++ -Wl,-rpath,'$$ORIGIN/../lib'

# ------------------------------
# 30. Sources
# ------------------------------
SRCS := $(wildcard $(src_udr)/*.cpp)
OBJS := $(SRCS:.cpp=.o)

.PHONY: all clean install prepare help print-vars

# =====================================================
# 40. Version header generator
# =====================================================
$(version_h):
	@echo "[gen] creating version.h"
	@mkdir -p $(src_udr)
	@printf '#pragma once\n#define UDR_VERSION "5.x-dev-%s"\nstatic const char* version = UDR_VERSION;\n' "$$(date +%Y%m%d)" > $(version_h)

# =====================================================
# 50. Build targets
# =====================================================
all: prepare $(bin_dir)/$(app_udr)

clean:
	@echo "[clean] removing previous UDR build outputs"
	@rm -rf $(OBJS) $(dist_udr) $(src_udr)/version.h $(app_udr) >/dev/null 2>&1 || true
	@echo "[clean] done."

# =====================================================
# 60. Prepare - locate and stage UDT libs
# =====================================================
prepare:
	@echo "[prepare] staging UDT artifacts"
	@mkdir -p $(bin_dir) $(lib_dir)
	@udt_sources=$$(find $(dist_udt) -maxdepth 1 -type f \( -name "libudt*.so" -o -name "libudt*.a" \) | sort); \
	if [ -n "$$udt_sources" ]; then \
		for f in $$udt_sources; do \
			base=$$(basename "$$f"); \
			cp -f "$$f" $(lib_dir)/"$$base"; \
			case "$$base" in \
				libudt*.so) cp -f "$$f" $(lib_dir)/libudt.so ;; \
				libudt*.a)  cp -f "$$f" $(lib_dir)/libudt.a ;; \
			esac; \
		done; \
		echo "[prepare] staged: $$udt_sources"; \
	else \
		echo "[error] no libudt found in $(dist_udt)" >&2; \
		echo "[hint] build UDT first: cd $(udt_root) && make -f make_linux.mak"; \
		exit 2; \
	fi

# =====================================================
# 70. Compile (quiet/verbose controlled by DEBUG)
# =====================================================
$(src_udr)/%.o: $(src_udr)/%.cpp $(version_h)
	@echo "[cc] compiling $<"
ifeq ($(DEBUG),1)
	$(CXX) $(CXXFLAGS) -c $< -o $@
else
	@$(CXX) $(CXXFLAGS) -c $< -o $@ 2>/dev/null
endif

# =====================================================
# 80. Link (auto static/shared)
# =====================================================
$(bin_dir)/$(app_udr): $(OBJS)
	@echo "[link] building $(app_udr)"
	@if [ -f $(lib_dir)/libudt.a ]; then \
		echo "[link] using static libudt.a"; \
		if [ "$(DEBUG)" = "1" ]; then \
			$(CXX) $(OBJS) -o $(bin_dir)/$(app_udr) \
				-L$(lib_dir) -L$(dist_udt) $(LDFLAGS_STATIC); \
		else \
			@$(CXX) $(OBJS) -o $(bin_dir)/$(app_udr) \
				-L$(lib_dir) -L$(dist_udt) $(LDFLAGS_STATIC) 2>/dev/null; \
		fi; \
	elif [ -f $(lib_dir)/libudt.so ]; then \
		echo "[link] using shared libudt.so"; \
		if [ "$(DEBUG)" = "1" ]; then \
			$(CXX) $(OBJS) -o $(bin_dir)/$(app_udr) \
				-L$(lib_dir) -L$(dist_udt) $(LDFLAGS_SHARED); \
		else \
			@$(CXX) $(OBJS) -o $(bin_dir)/$(app_udr) \
				-L$(lib_dir) -L$(dist_udt) $(LDFLAGS_SHARED) 2>/dev/null; \
		fi; \
	else \
		echo "[error] no libudt found in $(lib_dir)" >&2; \
		exit 3; \
	fi
	@echo "[done] built $(bin_dir)/$(app_udr)"

# =====================================================
# 90. Install
# =====================================================
install: all
	@echo "[install] staging artifacts"
	@if [ -f $(lib_dir)/libudt.a ]; then echo "[pack] static libudt.a staged"; fi
	@if [ -f $(lib_dir)/libudt.so ]; then echo "[pack] shared libudt.so staged"; fi
	@echo "[done] build artifacts available under $(dist_udr)/"

# =====================================================
# 100. Utilities
# =====================================================
print-vars:
	@echo "root_dir   = $(root_dir)"
	@echo "src_dir    = $(src_dir)"
	@echo "udt_root   = $(udt_root)"
	@echo "udr_root   = $(udr_root)"
	@echo "dist_udt   = $(dist_udt)"
	@echo "dist_udr   = $(dist_udr)"
	@echo "bin_dir    = $(bin_dir)"
	@echo "lib_dir    = $(lib_dir)"
	@echo "app_udr    = $(app_udr)"
	@echo "DEBUG      = $(DEBUG)"

help:
	@echo "Targets:"
	@echo "  make all         - Build UDR quietly (prepare + compile)"
	@echo "  make DEBUG=1     - Build with full warnings/logs"
	@echo "  make clean       - Remove outputs"
	@echo "  make install     - Copy binaries/libs to dist/"
	@echo "  make print-vars  - Show resolved paths"
