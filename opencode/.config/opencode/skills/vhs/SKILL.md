---
name: vhs
description: "Create reproducible CLI demo recordings with Charmbracelet VHS. Use on 'vhs', 'tape', 'cli demo', 'terminal gif', 'terminal video'."
---

# VHS Skill

Create polished CLI demos by writing `.tape` scripts for Charmbracelet VHS.

## When to Use

- Recording CLI demos for docs or marketing
- Reproducible terminal GIF/MP4/WebM renders
- CLI integration testing via ASCII output

## Prereqs (Read-Only Guidance)

- VHS requires `ttyd` and `ffmpeg` on PATH
- Fast local run: `vhs demo.tape`
- Docker run (no local deps):
  ```bash
  docker run --rm -v $PWD:/vhs ghcr.io/charmbracelet/vhs demo.tape
  ```

## Tape Structure Rules

- `Require` and `Set` commands must appear before any non-setting command
- Use `Output` to define artifacts (`.gif`, `.mp4`, `.webm`, `.ascii`)
- Prefer deterministic outputs (no timestamps, no non-deterministic commands)

## Recommended Defaults

```elixir
Output demo.gif
Set Width 1200
Set Height 600
Set FontSize 34
Set TypingSpeed 80ms
Set CursorBlink false
```

## Demo Flow Template

```elixir
Output demo.gif
Set Width 1200
Set Height 600
Set FontSize 34
Set TypingSpeed 80ms
Set CursorBlink false

Require <your-cli>

Hide
Type "./your-cli --version"
Enter
Show

Type "./your-cli help"
Enter
Sleep 1s

Type "./your-cli demo"
Enter
Wait /Done/
Sleep 1s
```

## Core Commands to Use

- `Type`, `Enter`, `Sleep`, `Wait` for pacing
- `Hide`/`Show` for setup/cleanup not shown on screen
- `Require` to fail fast if dependencies are missing
- `Output` for multiple formats when needed

## Best Practices

- Use `Wait /regex/` for long-running commands instead of fixed sleeps
- Use `Hide` for build/setup, `Show` for the visible demo
- Avoid spinners or long logs that bloat GIFs
- Prefer short demos with clear success output
- Use `Output demo.ascii` for golden-file testing in CI

## Common Pitfalls

- `Set` commands placed after `Type` (ignored)
- Non-deterministic output (timestamps, random IDs)
- Missing `Require` for needed binaries
- Long-running commands without `Wait`

## Output Format

When asked to create a tape, respond with:

```
Tape: <path>
Outputs: <list>
Notes: <assumptions or prerequisites>
```
