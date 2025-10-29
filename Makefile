# =====================================================
# UDR Master Makefile (robust, single-level build)
# =====================================================
#   - No sub-makefiles required
#   - External UDT under ../udt/dist
#   - Works with static (.a) or shared (.so)
#   - Auto-generates version.h safely
# =====================================================

CXX        = g++
OS         ?= LINUX
ARCH       ?= AMD64
SRC_DIR    = src
DIST_DIR   = dist
UDT_DIR    = ../udt/dist
APP        = udr
VERSION_H  = $(SRC_DIR)/version.h

SRCS       = $(wildcard $(SRC_DIR)/*.cpp)
OBJS       = $(SRCS:.cpp=.o)
# =====================================================
# 02. Compiler and linker flags (auto include discovery)
# =====================================================
INC_PATHS := $(shell find $(SRC_DIR) -type d 2>/dev/null)
CXXFLAGS  = -Wall -D$(OS) -finline-functions -g -I../udt/src $(addprefix -I,$(INC_PATHS))

# Shared/static lib discovery and runtime search path
LDFLAGS   = -Wl,-rpath,'$$ORIGIN' -Wl,-rpath,'$$ORIGIN/../udt/dist' \
             -L$(DIST_DIR) -L../udt/dist
LDLIBS    = -ludt -lssl -lcrypto -lz -lpthread -lm



.PHONY: all clean install prepare help

# =====================================================
# 05. Generate version header
# =====================================================
$(VERSION_H):
        @echo "[gen] creating version.h"
        @mkdir -p $(SRC_DIR)
        @printf '#pragma once\n#define UDR_VERSION "5.x-dev-%s"\nstatic const char* version = UDR_VERSION;\n' "$$(date +%Y%m%d)" > $(VERSION_H)

# =====================================================
# 10. Build targets
# =====================================================
all: prepare $(DIST_DIR)/$(APP)

clean:
        @echo "[clean] removing previous UDR build outputs"
        rm -rf $(OBJS) $(DIST_DIR) $(SRC_DIR)/version.h $(APP)
        @echo "[clean] done."

# =====================================================
# 20. Prepare — locate UDT lib
# =====================================================
prepare:
        @echo "[prepare] locating external UDT library"
        @mkdir -p $(DIST_DIR)
        @udt_files=$$(find $(UDT_DIR) -maxdepth 1 -type f \( -name "libudt*.so" -o -name "libudt*.a" \) | sort); \
        if [ -n "$$udt_files" ]; then \
                for f in $$udt_files; do \
                        base=$$(basename "$$f"); \
                        cp -f "$$f" $(DIST_DIR)/"$$base"; \
                        case "$$base" in \
                                libudt*.so) ln -sf "$$base" $(DIST_DIR)/libudt.so ;; \
                                libudt*.a)  ln -sf "$$base" $(DIST_DIR)/libudt.a ;; \
                        esac; \
                done; \
                echo "[link] using external UDT library: $$udt_files"; \
        else \
                echo "[error] no libudt found in $(UDT_DIR)" >&2; \
                echo "[hint] build UDT first: cd ../udt && make -f make_linux.mak"; \
                exit 2; \
        fi

# =====================================================
# 30. Build and link
# =====================================================
# =====================================================
# 30. Build and link
# =====================================================
$(SRC_DIR)/%.o: $(SRC_DIR)/%.cpp $(VERSION_H)
        @echo "[cc] compiling $<"
        $(CXX) $(CXXFLAGS) -c $< -o $@

$(DIST_DIR)/$(APP): $(OBJS)
        @echo "[link] building $(APP)"
        @mkdir -p $(DIST_DIR)
        @if [ ! -f $(DIST_DIR)/libudt.so ] && [ ! -f $(DIST_DIR)/libudt.a ]; then \
                echo "[error] no UDT library found in $(DIST_DIR)" >&2; \
                exit 3; \
        fi
        @echo "[link] using $$(ls $(DIST_DIR)/libudt.* 2>/dev/null | tr '\n' ' ')"
        $(CXX) $(OBJS) -o $(DIST_DIR)/$(APP) $(LDFLAGS) $(LDLIBS)
        @echo "[done] built $(DIST_DIR)/$(APP)"



# =====================================================
# 40. Install
# =====================================================
install: all
        @echo "[install] staging artifacts"
        @if [ -f $(DIST_DIR)/libudt.a ]; then echo "[pack] static libudt.a staged"; fi
        @if [ -f $(DIST_DIR)/libudt.so ]; then echo "[pack] shared libudt.so staged"; fi
        @echo "[done] build artifacts available under $(DIST_DIR)/"

# =====================================================
# 50. Help
# =====================================================
help:
        @echo "Targets:"
        @echo "  make all       - Full build (prepare + compile)"
        @echo "  make clean     - Remove outputs"
        @echo "  make install   - Copy binaries/libs to dist/"
        @echo "  make help      - Show this message"
