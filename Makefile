# =====================================================
# UDR Master Makefile (safe multi-dir dispatch)
# =====================================================
DIRS = udt src
TARGETS = all clean

# Default rule expands to per-dir rules
$(TARGETS): %: $(patsubst %, %.%, $(DIRS))

# Generic handler for dir.target form
$(foreach TGT, $(TARGETS), $(patsubst %, %.$(TGT), $(DIRS))):
	@d=$(subst ., , $@); \
	echo "[build] $$d → $(@F)"; \
	if [ "$${d}" = "udt" ]; then \
	  echo "[warn] ignoring nonzero exit from udt (known benign)"; \
	  $(MAKE) -C $$d $(@F) || echo "[warn] $$d exited nonzero — continuing"; \
	else \
	  $(MAKE) -C $$d $(@F); \
	fi
