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
# Compiler and linker flags (auto include discovery)
# =====================================================
INC_PATHS := $(shell find $(SRC_DIR) -type d 2>/dev/null)
CCFLAGS    = -Wall -D$(OS) -finline-functions -g -I../udt/src $(addprefix -I,$(INC_PATHS))
LDFLAGS    = -lstdc++ -lpthread -lm -lssl -lcrypto



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
        @udt_file=$$(find $(UDT_DIR) -maxdepth 1 -type f -name "libudt*.[as][ao]" | head -n 1); \
        if [ -n "$$udt_file" ]; then \
                cp -f "$$udt_file" $(DIST_DIR)/; \
                echo "[link] using external UDT library: $$(basename $$udt_file)"; \
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
        $(CXX) $(CCFLAGS) -c $< -o $@

$(DIST_DIR)/$(APP): $(OBJS)
        @echo "[link] building $(APP)"
        @mkdir -p $(DIST_DIR)
        @LIBFILE=$$(find $(DIST_DIR) -maxdepth 1 -type f \( -name "libudt*.a" -o -name "libudt*.so" \) | head -n 1); \
        if [ -z "$$LIBFILE" ]; then \
                echo "[error] no UDT library found in $(DIST_DIR)" >&2; \
                exit 3; \
        else \
                echo "[link] using $$LIBFILE"; \
                $(CXX) $(OBJS) -o $(DIST_DIR)/$(APP) -L$(DIST_DIR) -lstdc++ -lpthread -lm -lssl -lcrypto $$LIBFILE; \
        fi
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