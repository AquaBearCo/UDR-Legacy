# =====================================================
# UDR Master Makefile (external UDT linkage, safe build)
# =====================================================
# This version assumes:
#   - External UDT already built under ../../udt/dist/
#   - No embedded UDT subproject here
#   - Works on Linux and Windows (Git Bash)
# =====================================================

TARGETS = all clean

# Default build target
all: prepare src.all

clean:
	@echo "[clean] removing previous UDR build outputs"
	-@$(MAKE) -C src clean || true
	@rm -rf dist

# =====================================================
# 10. Prepare phase — link external UDT library
# =====================================================
prepare:
	@echo "[prepare] linking external UDT library"
	@if [ ! -d src ]; then mkdir -p src; fi
	@if [ -f ../../udt/dist/libudt-2.3.2.a ]; then \
		ln -sf ../../udt/dist/libudt-2.3.2.a src/libudt.a; \
		echo "[link] external UDT library linked from ../../udt/dist"; \
	else \
		echo "[error] external libudt-2.3.2.a not found in ../../udt/dist" >&2; \
		exit 2; \
	fi

# =====================================================
# 20. Build UDR core
# =====================================================
src.all:
	@echo "[build] building UDR core sources"
	$(MAKE) -C src all

# =====================================================
# 30. Dist aggregation
# =====================================================
install:
	@mkdir -p dist
	@if [ -f src/udr ]; then cp -f src/udr dist/; fi
	@if [ -f src/libudt.a ]; then cp -f src/libudt.a dist/; fi
	@echo "[done] build artifacts staged in dist/"
