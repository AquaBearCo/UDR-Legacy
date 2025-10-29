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
BIN_DIR    = $(DIST_DIR)/bin
LIB_DIR    = $(DIST_DIR)/lib
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
all: prepare $(BIN_DIR)/$(APP)

clean:
	@echo "[clean] removing previous UDR build outputs"
	rm -rf $(OBJS) $(DIST_DIR) $(SRC_DIR)/version.h $(APP)
	@echo "[clean] done."

# =====================================================
# 20. Prepare - locate UDT lib
# =====================================================
prepare:
	@echo "[prepare] staging build directories"
	@mkdir -p $(BIN_DIR) $(LIB_DIR)
	@echo "[prepare] syncing UDT artifacts from $(UDT_DIR)"
	@udt_sources=$$(find $(UDT_DIR) -maxdepth 1 -type f \( -name "libudt*.so" -o -name "libudt*.a" \) | sort); \
	if [ -n "$$udt_sources" ]; then \
		for f in $$udt_sources; do \
			base=$$(basename "$$f"); \
			cp -f "$$f" $(LIB_DIR)/"$$base"; \
			case "$$base" in \
				libudt*.so) cp -f "$$f" $(LIB_DIR)/libudt.so ;; \
				libudt*.a)  cp -f "$$f" $(LIB_DIR)/libudt.a ;; \
			esac; \
		done; \
		echo "[prepare] staged: $$udt_sources"; \
	else \
		echo "[error] no libudt found in $(UDT_DIR)" >&2; \
		echo "[hint] build UDT first: cd ../udt && make -f make_linux.mak"; \
		exit 2; \
	fi

# =====================================================
# 30. Build and link
# =====================================================
$(SRC_DIR)/%.o: $(SRC_DIR)/%.cpp $(VERSION_H)
	@echo "[cc] compiling $<"
	$(CXX) $(CXXFLAGS) -c $< -o $@

# =====================================================
# 35. Link: static preferred with shared fallback
# =====================================================
$(BIN_DIR)/$(APP): $(OBJS)
	@echo "[link] building $(APP)"
	@if [ -f $(LIB_DIR)/libudt-2.3.2.a ]; then \
		echo "[link] using static libudt-2.3.2.a"; \
		$(CXX) $(OBJS) -o $(BIN_DIR)/$(APP) \
			-L$(LIB_DIR) -L$(UDT_DIR) -ludt \
			-lssl -lcrypto -lz -lpthread -lm -static-libstdc++; \
	elif [ -f $(LIB_DIR)/libudt-2.3.2.so ]; then \
		echo "[link] using shared libudt-2.3.2.so"; \
		$(CXX) $(OBJS) -o $(BIN_DIR)/$(APP) \
			-L$(LIB_DIR) -L$(UDT_DIR) -ludt \
			-Wl,-rpath,'$$ORIGIN/../lib' \
			-lssl -lcrypto -lz -lpthread -lm -lstdc++; \
	else \
		echo "[error] no libudt found under $(LIB_DIR)" >&2; \
		exit 3; \
	fi
	@echo "[done] built $(BIN_DIR)/$(APP)"



# =====================================================
# 40. Install
# =====================================================
install: all
	@echo "[install] staging artifacts"
	@if [ -f $(LIB_DIR)/libudt.a ]; then echo "[pack] static libudt.a staged"; fi
	@if [ -f $(LIB_DIR)/libudt.so ]; then echo "[pack] shared libudt.so staged"; fi
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
