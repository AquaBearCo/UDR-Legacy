# Agent instructions for the UDR repository

These guidelines apply to the entire repository unless a subdirectory overrides
them with its own `AGENTS.md`.

- Prefer Python 3.9+ features when updating the `server/` code and keep the
  scripts executable as standalone entry points.
- Add type hints and docstrings for new Python functions.
- For C++ sources, follow the existing brace style (opening braces on the same
  line) and keep logging via the existing helper macros unless the change is
  scoped to logging improvements.
- Keep documentation in Markdown format and wrap lines at 100 characters when
  practical.
