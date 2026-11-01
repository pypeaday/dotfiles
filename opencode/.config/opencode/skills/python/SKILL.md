---
name: python
description: 'Python development patterns, testing, async, data modeling, and debugging. Triggers on "python", "pytest", "pydantic", "async", "fastapi", "type hint", "dataclass".'
---

# Python Development Skill

## Project Structure

### Standard src Layout
```
project/
├── pyproject.toml
├── src/
│   └── mypackage/
│       ├── __init__.py
│       ├── core.py
│       ├── models.py
│       └── exceptions.py
├── tests/
│   ├── conftest.py
│   ├── test_core.py
│   └── test_models.py
└── README.md
```

### When to Use What
| Structure | Use Case |
|-----------|----------|
| src layout | Libraries, packages published to PyPI |
| flat layout | Internal apps, scripts, services |
| PEP 723 script | Single-file tools (`uv run` inline deps) |

## Type Hints

### Essential Patterns
```python
from typing import Any
from collections.abc import Sequence, Mapping, Iterator

# Prefer builtins (3.10+)
def process(items: list[str], config: dict[str, Any]) -> bool: ...

# Union syntax (3.10+)
def find(key: str) -> str | None: ...

# Callable
from collections.abc import Callable
def retry(fn: Callable[..., Any], attempts: int = 3) -> Any: ...

# TypeVar for generics
from typing import TypeVar
T = TypeVar("T")
def first(items: Sequence[T]) -> T | None:
    return items[0] if items else None
```

### When NOT to Type
- Throwaway scripts
- Test internals (type the fixtures, not every assertion)
- When `Any` would be the only option — rethink the design instead

## Data Modeling

### Decision Tree
```
Need validation + serialization? → Pydantic BaseModel
Need lightweight struct?        → dataclass
Need dict compatibility?        → TypedDict
Need immutable?                 → frozen dataclass or NamedTuple
```

### Pydantic Patterns
```python
from pydantic import BaseModel, Field, field_validator

class Config(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    replicas: int = Field(default=1, ge=1, le=100)
    tags: list[str] = Field(default_factory=list)

    @field_validator("name")
    @classmethod
    def name_must_be_slug(cls, v: str) -> str:
        if not v.replace("-", "").isalnum():
            raise ValueError("name must be alphanumeric with hyphens")
        return v.lower()

# Serialization
config = Config(name="my-app", replicas=3)
config.model_dump()        # dict
config.model_dump_json()   # JSON string
Config.model_validate(d)   # from dict
Config.model_validate_json(s)  # from JSON
```

### Dataclass Patterns
```python
from dataclasses import dataclass, field

@dataclass(frozen=True, slots=True)
class Point:
    x: float
    y: float

@dataclass
class Config:
    name: str
    items: list[str] = field(default_factory=list)
```

## Error Handling

### Exception Hierarchy
```python
class AppError(Exception):
    """Base for all application errors."""

class NotFoundError(AppError):
    """Resource not found."""
    def __init__(self, resource: str, id: str):
        self.resource = resource
        self.id = id
        super().__init__(f"{resource} {id} not found")

class ValidationError(AppError):
    """Invalid input."""
```

### Patterns
```python
# Specific catches, never bare except
try:
    result = api_call()
except httpx.TimeoutException:
    logger.warning("API timeout, retrying")
    result = api_call()
except httpx.HTTPStatusError as e:
    if e.response.status_code == 404:
        raise NotFoundError("resource", id) from e
    raise

# Context managers for cleanup
from contextlib import contextmanager

@contextmanager
def managed_connection(url: str):
    conn = connect(url)
    try:
        yield conn
    finally:
        conn.close()
```

### Anti-Patterns
| ❌ Don't | ✅ Do |
|----------|-------|
| `except Exception: pass` | Catch specific exceptions, log or re-raise |
| `except: ...` (bare except) | Always specify exception type |
| `raise Exception("msg")` | Raise specific exception subclass |
| Return `None` for errors | Raise exceptions or use `Result` type |
| Catch and re-raise same exception | Only catch if you add context |

## Testing with pytest

### Fixtures
```python
# conftest.py
import pytest

@pytest.fixture
def sample_config():
    return Config(name="test", replicas=1)

@pytest.fixture
def tmp_db(tmp_path):
    db_path = tmp_path / "test.db"
    db = Database(str(db_path))
    db.init()
    yield db
    db.close()
```

### Parametrize
```python
@pytest.mark.parametrize("input,expected", [
    ("hello", "HELLO"),
    ("", ""),
    ("Hello World", "HELLO WORLD"),
])
def test_uppercase(input, expected):
    assert uppercase(input) == expected
```

### Testing Exceptions
```python
def test_not_found_raises():
    with pytest.raises(NotFoundError, match="user 123 not found"):
        find_user("123")
```

### Mocking
```python
from unittest.mock import patch, AsyncMock

def test_api_call(mocker):
    mock_get = mocker.patch("mypackage.core.httpx.get")
    mock_get.return_value.json.return_value = {"status": "ok"}

    result = fetch_status()
    assert result == "ok"
    mock_get.assert_called_once()

# Async mocking
async def test_async_call(mocker):
    mocker.patch("mypackage.core.fetch", new=AsyncMock(return_value=42))
    result = await process()
    assert result == 42
```

### Test Organization
```
tests/
├── conftest.py          # shared fixtures
├── unit/
│   ├── test_models.py   # pure logic
│   └── test_utils.py
├── integration/
│   └── test_api.py      # real I/O
└── fixtures/
    └── sample.json      # test data
```

## Async Patterns

### httpx for HTTP
```python
import httpx

async def fetch_all(urls: list[str]) -> list[dict]:
    async with httpx.AsyncClient(timeout=30.0) as client:
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks, return_exceptions=True)
        return [r.json() for r in responses if not isinstance(r, Exception)]
```

### asyncio Patterns
```python
import asyncio

# Gather with error handling
results = await asyncio.gather(*tasks, return_exceptions=True)
successes = [r for r in results if not isinstance(r, BaseException)]
failures = [r for r in results if isinstance(r, BaseException)]

# Semaphore for concurrency limiting
sem = asyncio.Semaphore(10)
async def limited_fetch(url):
    async with sem:
        return await client.get(url)

# Timeout
try:
    result = await asyncio.wait_for(slow_operation(), timeout=5.0)
except asyncio.TimeoutError:
    logger.error("Operation timed out")
```

## Logging

### structlog (preferred)
```python
import structlog

logger = structlog.get_logger()

def process_order(order_id: str):
    log = logger.bind(order_id=order_id)
    log.info("processing_order")
    try:
        result = do_work(order_id)
        log.info("order_processed", result=result)
    except Exception:
        log.exception("order_failed")
        raise
```

### stdlib logging
```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
)
logger = logging.getLogger(__name__)
```

## CLI Patterns

### click (simple)
```python
import click

@click.command()
@click.argument("name")
@click.option("--count", "-c", default=1, help="Number of greetings")
def hello(name: str, count: int):
    """Greet NAME count times."""
    for _ in range(count):
        click.echo(f"Hello, {name}!")
```

### typer (modern, type-hint based)
```python
import typer

app = typer.Typer()

@app.command()
def deploy(
    env: str = typer.Argument(..., help="Target environment"),
    dry_run: bool = typer.Option(False, "--dry-run", "-n"),
):
    """Deploy to ENV."""
    if dry_run:
        typer.echo(f"Would deploy to {env}")
        return
    do_deploy(env)
```

## Debugging

### Quick Debug
```python
# Drop into debugger at any point
breakpoint()  # Python 3.7+

# Or with environment variable
# PYTHONBREAKPOINT=ipdb.set_trace python script.py
```

### Reading Tracebacks
1. Read from **bottom up** — last frame is where error occurred
2. Note the **exception type and message** first
3. Scan frames for **your code** (skip stdlib/library frames)
4. Check the **variable values** at the failing line

## Common Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Mutable default args | `def f(items=[])` shared across calls | `def f(items=None): items = items or []` |
| Global state | Hard to test, race conditions | Dependency injection, pass explicitly |
| String typing | `if status == "active"` typos silently pass | Use `Enum` or `Literal` |
| Wildcard imports | `from x import *` pollutes namespace | Import explicitly |
| Nested try/except | Deep nesting obscures flow | Extract to functions |
| God classes | 500+ line class doing everything | Split by responsibility |
| Premature optimization | Complex code for imagined perf | Profile first (`py-spy`, `cProfile`) |

## Performance Profiling

```bash
# CPU profiling
py-spy record -o profile.svg -- python script.py

# Memory profiling
python -m tracemalloc script.py

# Quick timing
python -m timeit "expression"
```
