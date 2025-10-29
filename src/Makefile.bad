# =====================================================
# UDR Core Makefile — uses external ../../udt build
# =====================================================

CXX      = g++
OS      ?= LINUX
ARCH    ?= AMD64

# --- compiler flags ----------------------------------------------------------
CXXFLAGS = -Wall -D$(OS) -finline-functions -g -I../../udt/src
ifeq ($(ARCH),IA32)
	CXXFLAGS += -DIA32
endif
ifeq ($(ARCH),IA64)
	CXXFLAGS += -DIA64
endif
ifeq ($(ARCH),POWERPC)
	CXXFLAGS += -mcpu=powerpc
endif
ifeq ($(ARCH),SPARC)
	CXXFLAGS += -DSPARC
endif
ifeq ($(OS),OSX)
	CXXFLAGS += -I/usr/local/opt/openssl/include
endif

# --- linker flags ------------------------------------------------------------
UDT_LIB  = ../../udt/dist/libudt-2.3.2.a
LDFLAGS  = -L../../udt/dist $(UDT_LIB) -lstdc++ -lpthread -lm -lssl -lcrypto
ifeq ($(OS),UNIX)
	LDFLAGS += -lsocket
endif
ifeq ($(OS),OSX)
	LDFLAGS += -L/usr/local/opt/openssl/lib
endif
ifeq ($(OS),SUNOS)
	LDFLAGS += -lrt -lsocket
endif

# --- objects / targets -------------------------------------------------------
OBJS = udr.o udr_threads.o udr_util.o udr_options.o
APP  = udr

# --- rules -------------------------------------------------------------------
all: version $(APP)
	@echo "[done] UDR built → $(APP)"

version:
	@./version.sh

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $<

$(APP): $(OBJS)
	@if [ ! -f "$(UDT_LIB)" ]; then \
		echo "[error] missing external UDT library: $(UDT_LIB)"; \
		exit 2; \
	fi
	$(CXX) $(CXXFLAGS) -o $@ $(OBJS) $(LDFLAGS)

clean:
	rm -f *.o $(APP) version.h
