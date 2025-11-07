# UDR (UDP-based Data Transfer for rsync)

UDR is a wrapper around `rsync` that replaces the TCP transport with the
[UDP-based Data Transfer (UDT)](https://en.wikipedia.org/wiki/UDP-based_Data_Transfer_Protocol)
protocol. The goal of this fork is to keep the project buildable with modern tool
chains, document the maintenance status, and provide guidance for anyone who
needs to operate or extend the software.

> **Maintenance status**
> 
> UDR is no longer actively developed. The code builds and the tests pass on
> current Linux distributions, but the project should be considered in
> _maintenance mode_. If you can obtain the required throughput by tuning TCP
> congestion control (for example, using BBR) that approach is usually simpler
> and better supported.

## Repository layout

```
.
├── server/         # Python implementation of the udrd control daemon
├── src/            # C++ client implementation that wraps rsync
└── tests/          # Pytest-based functional smoke tests
```

## Getting started

### Prerequisites

* A C++ toolchain with GNU Make
* OpenSSL development libraries (`libssl-dev`/`openssl-devel`)
* Python 3.9+ (for the server component and the tests)
* `rsync`

### Building the client

```
make -C src
```

Use the `os` and `arch` environment variables if you need to cross-compile.
Refer to `src/Makefile` for the supported options.

### Running the tests

The tests expect a compiled `udr` binary under `src/`. Create and activate a
virtual environment, install the pinned test dependencies, and invoke `pytest`:

```
python -m venv .venv
source .venv/bin/activate
pip install -r tests/requirements.txt
pytest
```

### Running the server daemon

The Python daemon has been ported to Python 3 and now uses `argparse` for its
CLI. A minimal invocation looks like:

```
python server/udrserver.py --config /path/to/udrd.conf start
```

Use `foreground` instead of `start` to run the server in the current terminal
session during development. The default configuration locations can be found in
`server/udrserver.py`.

## Modernization highlights

* Python server updated for Python 3 compatibility (type hints, structured
  logging, safer file handling).
* Test suite uses contemporary `pytest` fixtures and dependencies.
* Documentation refreshed to reflect the maintenance status and supported
  tooling.

For a list of follow-up tasks and ideas, see [`TODO.md`](TODO.md).

## License

UDR is released under the Apache 2.0 License. See [`LICENSE.txt`](LICENSE.txt)
for the full text.
