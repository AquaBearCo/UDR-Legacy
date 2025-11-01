# Modernization backlog

The following items capture potential follow-up work to continue improving UDR.
None of them are required for basic usage, but they document areas where the
code base could benefit from additional attention.

## Build and packaging

- [ ] Add CI jobs (GitHub Actions) for building the C++ client and running tests
      on Linux.
- [ ] Provide container images or Vagrant boxes for reproducible development
      environments.
- [ ] Publish prebuilt `udr` binaries for common Linux distributions.

## Client (C++)

- [ ] Replace the bespoke logging macros with a structured logging library.
- [ ] Introduce clang-format/clang-tidy configuration and apply automatic
      formatting.
- [ ] Evaluate replacing deprecated OpenSSL APIs with their modern equivalents.

## Server (Python)

- [ ] Convert the daemon helper into a small installable Python package.
- [ ] Add type checking (mypy) and linting (ruff) to the development workflow.
- [ ] Implement unit tests for the configuration parser and connection handler.

## Documentation

- [ ] Provide step-by-step deployment guidance for the Python server, including
      production hardening recommendations.
- [ ] Document troubleshooting steps for the most common runtime issues.
- [ ] Expand the README with real-world performance examples and benchmarks.
