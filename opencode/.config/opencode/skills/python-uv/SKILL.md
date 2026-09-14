---
name: python-uv
description: 'Python tooling with uv: project management, scripts, packages, and CI. Triggers on "uv", "pyproject", "python setup", "pip install", "virtual environment", "python project".'
---

# Python (uv-first) Skill

Use `uv` for all Python workflows. It replaces pip, pip-tools, poetry, pyenv, and virtualenv.

## Rules

- Default to `uv` for running, installing, and tooling.
- Any standalone script you write MUST be a PEP 723 script and runnable as:

  ```bash
  uv run path/to/script.py
  ```

- Avoid `python path/to/script.py` in instructions.
  - Exception: CLI one-liners the agent runs during investigation, e.g. `python -c '...'`.
- Do not mention Poetry unless the repo is legacy and already requires it.
  - If Poetry is required, follow the repo convention; optionally propose migration to `uv` when appropriate.
- In greenfield repos, or legacy `setup.py`/pip projects, prefer moving to `pyproject.toml` + `uv` when appropriate.

## Project Lifecycle

### Create a New Project
```bash
uv init myproject              # creates pyproject.toml + hello.py
cd myproject
uv add httpx pydantic          # add dependencies
uv add --dev pytest ruff       # add dev dependencies
uv run python -m myproject     # run the project
```

### pyproject.toml Anatomy
```toml
[project]
name = "myproject"
version = "0.1.0"
description = "My project"
requires-python = ">=3.11"
dependencies = [
    "httpx>=0.27",
    "pydantic>=2.0",
]

[dependency-groups]
dev = [
    "pytest>=8.0",
    "ruff>=0.7",
    "mypy>=1.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

### Dependency Management
```bash
uv add <package>               # add to [project.dependencies]
uv add --dev <package>         # add to [dependency-groups] dev
uv remove <package>            # remove dependency
uv sync                        # install from lock file
uv lock                        # regenerate lock file
uv lock --upgrade              # upgrade all deps in lock
uv lock --upgrade-package httpx # upgrade one dep
```

### Lock File
- `uv.lock` is the lock file — commit it to git
- `uv sync` installs exactly what's in the lock
- `uv sync --frozen` fails if lock is out of date (use in CI)

## PEP 723 Scripts (Inline Dependencies)

```python
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "requests>=2",
#   "rich>=13",
# ]
# ///

def main() -> None:
    import requests
    from rich import print
    r = requests.get("https://httpbin.org/json")
    print(r.json())

if __name__ == "__main__":
    main()
```

Run with: `uv run script.py` — uv auto-creates an isolated env with the declared deps.

## Python Version Management

```bash
uv python install 3.12         # install Python 3.12
uv python install 3.11 3.12    # install multiple
uv python list                 # show installed versions
uv python pin 3.12             # pin for this project (.python-version)
```

## Virtual Environments

```bash
uv venv                        # create .venv (auto for most commands)
uv venv --python 3.12          # specific Python version
source .venv/bin/activate      # manual activation (rarely needed)
```

Note: `uv run` and `uv sync` auto-create and use `.venv` — you rarely need to manage it manually.

## Global CLI Tools

```bash
uv tool install ruff           # install globally
uv tool install 'httpie>=3.0'  # with version constraint
uv tool list                   # list installed tools
uv tool upgrade ruff           # upgrade a tool
uv tool run cowsay hello       # run without installing (ephemeral)
uvx cowsay hello               # shorthand for uv tool run
```

## Workspaces (Monorepo)

```toml
# Root pyproject.toml
[tool.uv.workspace]
members = ["packages/*"]
```

```
monorepo/
├── pyproject.toml              # workspace root
├── uv.lock                    # single lock file
├── packages/
│   ├── core/
│   │   └── pyproject.toml
│   ├── api/
│   │   └── pyproject.toml     # depends on core
│   └── cli/
│       └── pyproject.toml     # depends on core
```

```bash
uv sync                        # sync all workspace members
uv run --package api pytest    # run in specific package
```

## CI/CD Integration (GitHub Actions)

```yaml
- uses: astral-sh/setup-uv@v4
  with:
    version: "latest"
- run: uv sync --frozen         # install deps (fail if lock stale)
- run: uv run pytest            # run tests
- run: uv run ruff check .      # lint
- run: uv run ruff format --check .  # format check
```

## Migration Guides

### From pip/requirements.txt
```bash
# Import existing requirements
uv add $(cat requirements.txt | grep -v '^#' | grep -v '^$' | tr '\n' ' ')
# Or start fresh
uv init && uv add <key-deps>
# Then delete requirements.txt
```

### From Poetry
```bash
# uv reads pyproject.toml natively
# Just run:
uv lock    # generates uv.lock from existing pyproject.toml
uv sync    # install
# Poetry.lock and poetry sections can be removed after validating
```

## Command Quick Reference

| Task | Command |
|------|---------|
| New project | `uv init myproject` |
| Add dep | `uv add httpx` |
| Add dev dep | `uv add --dev pytest` |
| Remove dep | `uv remove httpx` |
| Install from lock | `uv sync` |
| Update lock | `uv lock --upgrade` |
| Run script | `uv run script.py` |
| Run module | `uv run python -m mypackage` |
| Run tool | `uvx ruff check .` |
| Install Python | `uv python install 3.12` |
| Pin Python | `uv python pin 3.12` |
| Build package | `uv build` |
| Publish | `uv publish` |
