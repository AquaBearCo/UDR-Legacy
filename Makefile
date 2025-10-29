# =====================================================
# UDR Master Makefile (external UDT linkage, safe build)
# =====================================================
#   - Uses external UDT under ../../udt/dist/
#   - Works on Linux and Windows Git Bash
#   - Continues even if sub-builds return non-zero (warnings)
# =====================================================

TARGETS = all clean install
APP = version.h udr

# =====================================================
# 05. Version header auto-generation
# =====================================================
version.h:
	@echo "[gen] creating version.h"
	@echo '#ifndef UDR_VERSION' > version.h
	@echo '#define UDR_VERSION "5.x-dev-$(shell date +%Y%m%d)"' >> version.h
	@echo '#endif' >> version.h

# =====================================================
# 10. Default build target
# =====================================================
all: prepare src.all

clean:
	@echo "[clean] removing previous UDR build outputs"
	-@$(MAKE) -C src clean || true
	@rm -rf dist version.h
	@echo "[clean] done."

# =====================================================
# 20. Prepare phase — link external UDT library
# =====================================================
prepare:
	@echo "[prepare] linking external UDT library"
	@mkdir -p src
	@if [ -f ../../udt/dist/libudt-2.3.2.a ]; then \
		ln -sf ../../udt/dist/libudt-2.3.2.a src/libudt.a 2>/dev/null || \
		cp -f ../../udt/dist/libudt-2.3.2.a src/libudt.a; \
		echo "[link] external UDT static lib linked from ../../udt/dist"; \
	elif [ -f ../../udt/dist/libudt-2.3.2.so ]; then \
		ln -sf ../../udt/dist/libudt-2.3.2.so src/libudt.so 2>/dev/null || \
		cp -f ../../udt/dist/libudt-2.3.2.so src/libudt.so; \
		echo "[link] external UDT shared lib linked from ../../udt/dist"; \
	else \
		echo "[error] external libudt-2.3.2.(a|so) not found in ../../udt/dist" >&2; \
		exit 2; \
	fi

# =====================================================
# 30. Build UDR core
# =====================================================
src.all:
	@echo "[build] building UDR core sources"
	@if [ -d src ]; then \
		$(MAKE) -C src all || echo "[warn] src exited non-zero — continuing"; \
	else \
		echo "[error] missing src directory — cannot build UDR core" >&2; \
		exit 3; \
	fi

# =====================================================
# 40. Dist aggregation
# =====================================================
install:
	@mkdir -p dist
	@if [ -f src/udr ]; then cp -f src/udr dist/; fi
	@if [ -f src/libudt.a ]; then cp -f src/libudt.a dist/; fi
	@if [ -f src/libudt.so ]; then cp -f src/libudt.so dist/; fi
	@echo "[done] build artifacts staged in dist/"
