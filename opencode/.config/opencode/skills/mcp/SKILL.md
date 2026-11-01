---
name: mcp
description: 'Build MCP servers and tools with Python FastMCP SDK. Triggers on "mcp", "mcp server", "mcp tool", "fastmcp", "model context protocol".'
---

# MCP (Model Context Protocol) Development Skill

## Overview

MCP lets AI agents call external tools, read resources, and use prompt templates via a standardized protocol. Build servers in Python using the FastMCP SDK.

## Architecture

```
AI Agent (Client)
  ↕ MCP Protocol (stdio | streamable-http)
MCP Server
  ├── Tools     → functions the agent can call
  ├── Resources → data the agent can read
  └── Prompts   → reusable prompt templates
```

## Quick Start

### Project Setup
```bash
uv init mcp-server-demo
cd mcp-server-demo
uv add "mcp[cli]"
```

### Minimal Server (stdio)
```python
# /// script
# requires-python = ">=3.11"
# dependencies = ["mcp[cli]"]
# ///
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-server")

@mcp.tool()
def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b

if __name__ == "__main__":
    mcp.run()
```

## Tools

Tools are functions the agent can call. Type hints are **mandatory** — they drive schema generation.

### Basic Tool
```python
@mcp.tool()
def search_logs(query: str, limit: int = 10) -> list[dict]:
    """Search application logs by keyword."""
    return db.search(query, limit=limit)
```

### Tool with Structured Output
```python
from pydantic import BaseModel, Field

class DeployStatus(BaseModel):
    app: str
    version: str
    status: str = Field(description="running | deploying | failed")
    replicas: int

@mcp.tool()
def get_deploy_status(app: str) -> DeployStatus:
    """Get deployment status for an application."""
    return DeployStatus(app=app, version="1.2.3", status="running", replicas=3)
```

### Tool with Context (logging, progress)
```python
from mcp.server.fastmcp import Context

@mcp.tool()
async def process_batch(items: list[str], ctx: Context) -> str:
    """Process a batch of items with progress reporting."""
    total = len(items)
    results = []
    for i, item in enumerate(items):
        await ctx.report_progress(i, total, f"Processing {item}")
        await ctx.info(f"Working on {item}")
        results.append(await do_work(item))
    return f"Processed {total} items"
```

### Tool with Image Return
```python
from mcp.server.fastmcp import Image

@mcp.tool()
def generate_chart(data: list[float]) -> Image:
    """Generate a chart from data points."""
    buf = create_chart(data)  # returns bytes
    return Image(data=buf, format="png")
```

## Resources

Resources are data endpoints the agent can read (like GET endpoints).

### Static Resource
```python
@mcp.resource("config://app")
def get_config() -> str:
    """Return application configuration."""
    return json.dumps(load_config(), indent=2)
```

### Dynamic Resource (URI template)
```python
@mcp.resource("logs://{service}/{level}")
def get_logs(service: str, level: str) -> str:
    """Get logs for a service at a specific level."""
    return "\n".join(fetch_logs(service, level))
```

## Prompts

Reusable prompt templates for common workflows.

```python
from mcp.server.fastmcp.prompts import base

@mcp.prompt()
def review_code(code: str, language: str = "python") -> list[base.Message]:
    """Create a code review prompt."""
    return [
        base.UserMessage(f"Review this {language} code for bugs and improvements:"),
        base.UserMessage(code),
    ]
```

## Transport

### stdio (default) — for local CLI tools
```python
mcp.run()  # or mcp.run(transport="stdio")
```

### Streamable HTTP — for remote/web servers
```python
mcp.run(transport="streamable-http")
# Serves on http://localhost:8000/mcp by default
```

### Mount in existing FastAPI/Starlette
```python
from starlette.applications import Starlette
from starlette.routing import Mount

app = Starlette(routes=[
    Mount("/mcp", app=mcp.streamable_http_app()),
])
```

## Lifespan (Startup/Shutdown)

Manage shared resources (DB connections, clients) with lifespan:

```python
from contextlib import asynccontextmanager
from dataclasses import dataclass

@dataclass
class AppState:
    db: Database
    client: httpx.AsyncClient

@asynccontextmanager
async def lifespan(server: FastMCP):
    db = await Database.connect(os.environ["DB_URL"])
    client = httpx.AsyncClient()
    try:
        yield AppState(db=db, client=client)
    finally:
        await client.aclose()
        await db.disconnect()

mcp = FastMCP("my-server", lifespan=lifespan)

@mcp.tool()
async def query(sql: str, ctx: Context) -> str:
    """Run a database query."""
    state = ctx.request_context.lifespan_context
    return str(await state.db.fetch(sql))
```

## Testing

### MCP Inspector (interactive)
```bash
uv run mcp dev server.py
# Opens browser UI for testing tools/resources
```

### Install in Claude Desktop
```bash
uv run mcp install server.py
# Adds to Claude Desktop's MCP config
```

### Programmatic Testing
```python
import pytest
from mcp.server.fastmcp import FastMCP

@pytest.fixture
def mcp_server():
    mcp = FastMCP("test")
    # register tools...
    return mcp

async def test_tool_directly():
    """Test the underlying function directly."""
    result = add(2, 3)
    assert result == 5
```

## Client Configuration

### Copilot CLI (copilot-mcp-config.yml)
```yaml
servers:
  my-server:
    command: uv
    args: ["run", "server.py"]
    env:
      API_KEY: "${API_KEY}"
```

### Claude Desktop (claude_desktop_config.json)
```json
{
  "mcpServers": {
    "my-server": {
      "command": "uv",
      "args": ["run", "server.py"],
      "env": { "API_KEY": "..." }
    }
  }
}
```

### Remote HTTP Server
```yaml
servers:
  remote-server:
    url: "https://mcp.example.com/mcp"
    headers:
      Authorization: "Bearer ${TOKEN}"
```

## Error Handling

```python
@mcp.tool()
async def safe_operation(input: str) -> str:
    """Operation with proper error handling."""
    try:
        result = await perform(input)
        return f"Success: {result}"
    except PermissionError:
        return "Error: insufficient permissions"
    except TimeoutError:
        return "Error: operation timed out, try again"
    except Exception as e:
        # Return error as string — don't raise (agent can't handle exceptions)
        return f"Error: {e}"
```

## Design Patterns

### Tool Design Rules
1. **Single responsibility** — one tool = one action
2. **Descriptive names** — `search_kubernetes_pods` not `search`
3. **Docstrings are descriptions** — the agent reads them to decide when to call
4. **Type everything** — drives schema generation and validation
5. **Return strings or Pydantic models** — agent needs readable output
6. **Handle errors gracefully** — return error messages, don't raise

### When to Use What
| MCP Concept | Analogous To | Use When |
|-------------|-------------|----------|
| Tool | POST endpoint / function call | Agent needs to perform an action |
| Resource | GET endpoint / file read | Agent needs to read data |
| Prompt | Stored procedure / template | Reusable multi-step workflows |

### Security Considerations
- Never expose raw SQL or shell exec without validation
- Use environment variables for secrets (never hardcode)
- Validate all inputs before executing
- Scope tool permissions narrowly (read-only where possible)
- Log tool invocations for audit

## Anti-Patterns

| ❌ Don't | ✅ Do |
|----------|-------|
| Missing type hints | Type every parameter and return |
| Missing docstrings | Every tool needs a clear description |
| Raising exceptions | Return error strings |
| God tools (does everything) | One focused action per tool |
| Hardcoded secrets | Use `os.environ` |
| Logging to stdout (stdio transport) | Log to stderr |
| No input validation | Validate before executing |
