# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "typer",
#     "iterfzf",
#     "rich",
#     "textual",
# ]
# ///
"""Workspace management for git repositories."""

import json
import os
import re
import shutil
import subprocess
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict
from dataclasses import dataclass
from pathlib import Path
from typing import Optional
from typing import cast

import typer
from iterfzf import iterfzf
from rich.console import Console
from rich.prompt import Confirm
from rich.prompt import Prompt
from rich.table import Table

app = typer.Typer(help="Manage git workspaces and worktrees")
workspace_app = typer.Typer(help="Manage workspaces")
worktree_app = typer.Typer(help="Manage worktrees within workspaces")
app.add_typer(workspace_app, name="workspace", help="Workspace management commands")
app.add_typer(worktree_app, name="worktree", help="Worktree management commands")
console = Console()

WORKSPACE_DIRS = {
    "personal": Path("~/projects/personal.workspaces").expanduser(),
    "work": Path("~/projects/work.workspaces").expanduser(),
}
WORKSPACE_METADATA = ".workspace.json"


@dataclass(frozen=True, slots=True)
class WorkspaceCheckout:
    area: str
    workspace: str
    name: str
    path: Path
    repo: Path
    ref: str
    mode: str
    role: str
    ephemeral: bool
    branch: str
    dirty: bool
    changed_files: int
    unpushed: int
    last_commit_timestamp: int | None
    age_days: int


@dataclass(frozen=True, slots=True)
class WorkspaceSummary:
    area: str
    name: str
    path: Path
    description: str
    checkouts: tuple[WorkspaceCheckout, ...]


@dataclass(frozen=True, slots=True)
class WorkspaceStats:
    area: str
    name: str
    path: Path
    checkouts: int
    repositories: int
    roles: tuple[tuple[str, int], ...]
    modes: tuple[tuple[str, int], ...]
    dirty_checkouts: int
    changed_files: int
    unpushed_commits: int
    unknown_push_state: int
    stale_checkouts: int
    last_commit_timestamp: int | None
    age_days: int


def git(*args, cwd=None):
    """Run git command."""
    cmd = ["git"]
    if cwd:
        cmd.extend(["-C", str(cwd)])
    cmd.extend(args)
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
    )


def _git_value(*args: str, cwd: Path) -> str:
    result = git(*args, cwd=cwd)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout.strip()


def _validate_name(value: str, label: str) -> str:
    value = value.strip()
    if not value or value in {".", ".."} or "/" in value or "\\" in value:
        raise ValueError(f"{label} must be a single non-empty path component")
    return value


def _metadata_path(workspace_path: Path) -> Path:
    return workspace_path / WORKSPACE_METADATA


def _load_metadata(workspace_path: Path) -> dict:
    path = _metadata_path(workspace_path)
    if not path.exists():
        return {
            "version": 1,
            "description": "",
            "checkouts": {},
        }
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"Cannot read workspace metadata {path}: {exc}") from exc
    if not isinstance(data, dict) or not isinstance(data.get("checkouts", {}), dict):
        raise RuntimeError(f"Invalid workspace metadata: {path}")
    data.setdefault("version", 1)
    data.setdefault("description", "")
    data.setdefault("checkouts", {})
    return data


def _save_metadata(workspace_path: Path, metadata: dict) -> None:
    path = _metadata_path(workspace_path)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n")
    temporary.replace(path)


def _main_worktree(path: Path) -> Path:
    output = _git_value("worktree", "list", "--porcelain", cwd=path)
    for line in output.splitlines():
        if line.startswith("worktree "):
            return Path(line.removeprefix("worktree ")).resolve()
    raise RuntimeError(f"Cannot find the main worktree for {path}")


def _checkout_branch(path: Path) -> str:
    branch = _git_value("branch", "--show-current", cwd=path)
    if branch:
        return branch
    commit = _git_value("rev-parse", "--short", "HEAD", cwd=path)
    return f"detached@{commit}"


def _checkout_safety_error(path: Path) -> str | None:
    status = _git_value("status", "--short", cwd=path)
    if status:
        return f"{path.name} has uncommitted changes"
    unpushed = get_unpushed_count(path)
    if unpushed < 0:
        return f"Cannot verify whether {path.name} has unpushed commits"
    if unpushed:
        return f"{path.name} has {unpushed} unpushed commit(s)"
    return None


def create_workspace_record(area: str, name: str, description: str = "") -> Path:
    """Create an empty orchestration workspace."""
    if area not in WORKSPACE_DIRS:
        raise ValueError("Area must be 'personal' or 'work'")
    name = _validate_name(name, "Workspace name")
    workspace_path = WORKSPACE_DIRS[area] / name
    if workspace_path.exists():
        raise ValueError(f"Workspace already exists: {workspace_path}")
    workspace_path.mkdir(parents=True)
    metadata = {
        "version": 1,
        "description": description.strip(),
        "checkouts": {},
    }
    _save_metadata(workspace_path, metadata)
    if description.strip():
        (workspace_path / "README.md").write_text(f"# {name}\n\n{description.strip()}\n")
    return workspace_path


def add_checkout(
    area: str,
    workspace: str,
    repo: Path,
    *,
    ref: str = "HEAD",
    mode: str = "detach",
    new_branch: str | None = None,
    name: str | None = None,
    role: str = "control",
    ephemeral: bool = False,
) -> Path:
    """Add a detached, existing-branch, or new-branch checkout."""
    if area not in WORKSPACE_DIRS:
        raise ValueError("Area must be 'personal' or 'work'")
    workspace_path = WORKSPACE_DIRS[area] / _validate_name(workspace, "Workspace name")
    if not workspace_path.is_dir():
        raise ValueError(f"Workspace does not exist: {workspace_path}")

    repo = repo.expanduser().resolve()
    repo_root = Path(_git_value("rev-parse", "--show-toplevel", cwd=repo)).resolve()
    ref = ref.strip() or "HEAD"
    role = role.strip() or "control"
    if mode not in {"detach", "existing", "new"}:
        raise ValueError("Mode must be 'detach', 'existing', or 'new'")
    if mode == "new":
        if not new_branch:
            raise ValueError("New branch mode requires a branch name")
        new_branch = new_branch.strip()
        _git_value("check-ref-format", "--branch", new_branch, cwd=repo_root)
        label = new_branch
    else:
        if new_branch:
            raise ValueError("A new branch name is only valid in new mode")
        label = role if mode == "detach" and ref == "HEAD" else ref

    safe_label = re.sub(r"[^A-Za-z0-9._-]+", "-", label).strip(".-") or mode
    folder_name = _validate_name(name or f"{repo_root.name}-{safe_label}", "Checkout name")
    target = workspace_path / folder_name
    if target.exists():
        raise ValueError(f"Checkout path already exists: {target}")

    if mode == "detach":
        args = ("worktree", "add", "--detach", str(target), ref)
    elif mode == "new":
        args = ("worktree", "add", "-b", cast(str, new_branch), str(target), ref)
    else:
        args = ("worktree", "add", str(target), ref)

    result = git(*args, cwd=repo_root)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "git worktree add failed")

    try:
        envrc = repo_root / ".envrc"
        if envrc.exists():
            shutil.copy(envrc, target / ".envrc")
        add_local_git_exclude(target, ".opencode/workspace-ticket.json")
        metadata = _load_metadata(workspace_path)
        metadata["checkouts"][folder_name] = {
            "repo": str(repo_root),
            "ref": ref,
            "mode": mode,
            "role": role,
            "ephemeral": ephemeral,
        }
        _save_metadata(workspace_path, metadata)
    except (OSError, RuntimeError):
        git("worktree", "remove", "--force", str(target), cwd=repo_root)
        if mode == "new" and new_branch:
            git("branch", "-D", new_branch, cwd=repo_root)
        raise
    return target


def remove_checkout(path: Path, *, force: bool = False) -> None:
    """Remove one checkout, refusing unsafe cleanup unless explicitly forced."""
    path = path.expanduser().resolve()
    if not path.is_dir() or not (path / ".git").exists():
        raise ValueError(f"Not a worktree: {path}")
    if not force:
        error = _checkout_safety_error(path)
        if error:
            raise RuntimeError(error)
    kill_tmux_windows_for_path(path)
    workspace_path = path.parent
    main_worktree = _main_worktree(path)
    args = ["worktree", "remove"]
    if force:
        args.append("--force")
    args.append(str(path))
    result = git(*args, cwd=main_worktree)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"Could not remove {path}")
    metadata = _load_metadata(workspace_path)
    metadata["checkouts"].pop(path.name, None)
    _save_metadata(workspace_path, metadata)


def remove_workspace_record(area: str, workspace: str, *, force: bool = False) -> None:
    """Remove a workspace and all of its checkouts."""
    if area not in WORKSPACE_DIRS:
        raise ValueError("Area must be 'personal' or 'work'")
    workspace_path = WORKSPACE_DIRS[area] / _validate_name(workspace, "Workspace name")
    if not workspace_path.is_dir():
        raise ValueError(f"Workspace not found: {workspace_path}")
    checkouts = [path for path in workspace_path.iterdir() if path.is_dir() and (path / ".git").exists()]
    if not force:
        managed_names = {path.name for path in checkouts}
        managed_names.update({WORKSPACE_METADATA, "README.md"})
        unexpected = [path.name for path in workspace_path.iterdir() if path.name not in managed_names]
        if unexpected:
            names = ", ".join(sorted(unexpected))
            raise RuntimeError(f"Workspace contains unmanaged content: {names}")
        errors = [error for path in checkouts if (error := _checkout_safety_error(path))]
        if errors:
            raise RuntimeError("; ".join(errors))
    for path in checkouts:
        remove_checkout(path, force=force)
    shutil.rmtree(workspace_path)

    kill_tmux_sessions(tmux_session_name(area, workspace))


def _scan_checkout(
    area: str,
    workspace_path: Path,
    path: Path,
    saved: dict,
) -> WorkspaceCheckout:
    """Read one checkout's Git state."""
    try:
        repo = Path(saved.get("repo") or _main_worktree(path))
        branch = _checkout_branch(path)
        status = _git_value("status", "--short", cwd=path)
        changed_files = len(status.splitlines())
        dirty = changed_files > 0
        unpushed = get_unpushed_count(path)
        last_commit_timestamp = get_commit_timestamp(path)
        age_days = int((time.time() - last_commit_timestamp) / 86400) if last_commit_timestamp is not None else -1
    except RuntimeError:
        repo = Path(saved.get("repo") or path)
        branch = "unreadable"
        dirty = True
        changed_files = 0
        unpushed = -1
        last_commit_timestamp = None
        age_days = -1
    return WorkspaceCheckout(
        area=area,
        workspace=workspace_path.name,
        name=path.name,
        path=path,
        repo=repo,
        ref=saved.get("ref") or branch,
        mode=saved.get("mode") or ("detach" if branch.startswith("detached@") else "existing"),
        role=saved.get("role") or "development",
        ephemeral=bool(saved.get("ephemeral", False)),
        branch=branch,
        dirty=dirty,
        changed_files=changed_files,
        unpushed=unpushed,
        last_commit_timestamp=last_commit_timestamp,
        age_days=age_days,
    )


def scan_workspaces() -> list[WorkspaceSummary]:
    """Return workspace state, inspecting checkouts concurrently."""
    workspaces: list[tuple[str, Path, dict, list[Path]]] = []
    for area, root in WORKSPACE_DIRS.items():
        if not root.exists():
            continue
        for workspace_path in sorted(path for path in root.iterdir() if path.is_dir()):
            metadata = _load_metadata(workspace_path)
            checkout_paths = [
                path for path in sorted(workspace_path.iterdir()) if path.is_dir() and (path / ".git").exists()
            ]
            workspaces.append((area, workspace_path, metadata, checkout_paths))

    summaries: list[WorkspaceSummary] = []
    with ThreadPoolExecutor(max_workers=8) as executor:
        scans = {
            (area, workspace_path): [
                executor.submit(
                    _scan_checkout,
                    area,
                    workspace_path,
                    path,
                    metadata["checkouts"].get(path.name, {}),
                )
                for path in checkout_paths
            ]
            for area, workspace_path, metadata, checkout_paths in workspaces
        }
        for area, workspace_path, metadata, _checkout_paths in workspaces:
            summaries.append(
                WorkspaceSummary(
                    area=area,
                    name=workspace_path.name,
                    path=workspace_path,
                    description=str(metadata.get("description", "")),
                    checkouts=tuple(future.result() for future in scans[(area, workspace_path)]),
                )
            )
    return summaries


def workspace_stats(summary: WorkspaceSummary, stale_days: int = 7) -> WorkspaceStats:
    """Aggregate management statistics for one workspace."""
    timestamps = [
        checkout.last_commit_timestamp for checkout in summary.checkouts if checkout.last_commit_timestamp is not None
    ]
    last_commit_timestamp = max(timestamps) if timestamps else None
    age_days = int((time.time() - last_commit_timestamp) / 86400) if last_commit_timestamp is not None else -1
    return WorkspaceStats(
        area=summary.area,
        name=summary.name,
        path=summary.path,
        checkouts=len(summary.checkouts),
        repositories=len({checkout.repo.resolve() for checkout in summary.checkouts}),
        roles=tuple(sorted(Counter(checkout.role for checkout in summary.checkouts).items())),
        modes=tuple(sorted(Counter(checkout.mode for checkout in summary.checkouts).items())),
        dirty_checkouts=sum(checkout.dirty for checkout in summary.checkouts),
        changed_files=sum(checkout.changed_files for checkout in summary.checkouts),
        unpushed_commits=sum(max(checkout.unpushed, 0) for checkout in summary.checkouts),
        unknown_push_state=sum(checkout.unpushed < 0 for checkout in summary.checkouts),
        stale_checkouts=sum(
            checkout.age_days >= stale_days for checkout in summary.checkouts if checkout.age_days >= 0
        ),
        last_commit_timestamp=last_commit_timestamp,
        age_days=age_days,
    )


def stats_report(stale_days: int = 7) -> dict:
    """Return a JSON-ready statistics report for all workspaces."""
    summaries = scan_workspaces()
    stats = [workspace_stats(summary, stale_days) for summary in summaries]
    role_counts = Counter(checkout.role for summary in summaries for checkout in summary.checkouts)
    mode_counts = Counter(checkout.mode for summary in summaries for checkout in summary.checkouts)
    workspace_rows = []
    for item in stats:
        row = asdict(item)
        row["path"] = str(item.path)
        row["roles"] = dict(item.roles)
        row["modes"] = dict(item.modes)
        workspace_rows.append(row)
    return {
        "generated_at": int(time.time()),
        "stale_days": stale_days,
        "totals": {
            "workspaces": len(stats),
            "checkouts": sum(item.checkouts for item in stats),
            "repositories": len({checkout.repo.resolve() for summary in summaries for checkout in summary.checkouts}),
            "roles": dict(sorted(role_counts.items())),
            "modes": dict(sorted(mode_counts.items())),
            "dirty_checkouts": sum(item.dirty_checkouts for item in stats),
            "changed_files": sum(item.changed_files for item in stats),
            "unpushed_commits": sum(item.unpushed_commits for item in stats),
            "unknown_push_state": sum(item.unknown_push_state for item in stats),
            "stale_checkouts": sum(item.stale_checkouts for item in stats),
        },
        "workspaces": workspace_rows,
    }


def get_all_repos() -> list[Path]:
    """Get repositories from the configured personal and work directories."""
    repos: list[Path] = []
    for base in (
        Path("~/projects/personal").expanduser(),
        Path("~/projects/work").expanduser(),
    ):
        if not base.exists():
            continue
        repos.extend(path for path in base.iterdir() if path.is_dir() and (path / ".git").exists())
    return sorted(repos)


def pick_repo() -> Optional[Path]:
    """Use fzf to pick a repository."""
    repos = get_all_repos()
    if not repos:
        console.print("[red]No repositories found[/red]")
        return None

    repo_names = [str(r) for r in repos]
    # Add exact matching for better search
    selected = cast(
        Optional[str],
        iterfzf(
            repo_names,
            prompt="Select repository: ",
            exact=True,  # Enable exact matching
            extended=True,  # Enable extended search mode
        ),
    )

    if selected:
        return Path(selected)
    return None


def pick_area() -> Optional[str]:
    """Pick workspace area (personal/work)."""
    areas = list(WORKSPACE_DIRS.keys())
    selected = cast(
        Optional[str],
        iterfzf(
            areas,
            prompt="Select area: ",
            exact=True,
            extended=True,
        ),
    )
    return selected


def pick_workspace(
    area: str,
) -> Optional[str]:
    """Pick an existing workspace."""
    ws_dir = WORKSPACE_DIRS[area]
    if not ws_dir.exists():
        return None

    workspaces = [d.name for d in ws_dir.iterdir() if d.is_dir()]
    if not workspaces:
        return None

    return cast(
        Optional[str],
        iterfzf(
            workspaces,
            prompt="Select workspace: ",
            exact=True,
            extended=True,
        ),
    )


def get_all_workspaces() -> list[tuple[str, Path]]:
    """Get all workspaces from all areas."""
    workspaces = []
    for ws_dir in WORKSPACE_DIRS.values():
        if ws_dir.exists():
            for ws in ws_dir.iterdir():
                if ws.is_dir():
                    workspaces.append((str(ws), ws))
    return workspaces


def get_all_directories() -> list[tuple[str, Path]]:
    """Get all repos and workspaces for universal open."""
    directories = []

    # Add dotfiles
    dotfiles = Path("~/dotfiles").expanduser()
    if dotfiles.exists():
        rel_path = "~/dotfiles"
        directories.append((rel_path, dotfiles))

    # Add regular repositories from personal and work
    for base_name in ["personal", "work"]:
        base = Path(f"~/projects/{base_name}").expanduser()
        if base.exists():
            for path in base.iterdir():
                if path.is_dir() and not path.name.endswith(".workspaces"):
                    rel_path = f"~/projects/{base_name}/{path.name}"
                    directories.append((rel_path, path))

    # Add workspaces
    for area, ws_dir in WORKSPACE_DIRS.items():
        if ws_dir.exists():
            for ws in ws_dir.iterdir():
                if ws.is_dir():
                    # Show workspaces with their area
                    rel_path = f"~/projects/{area}.workspaces/{ws.name}"
                    directories.append((rel_path, ws))

    return sorted(directories, key=lambda x: x[0])


def _tmux_name_component(value: str) -> str:
    """Encode a readable, collision-safe tmux name component."""
    parts = []
    for byte in value.encode():
        character = chr(byte)
        if character.isascii() and (character.isalnum() or character == "-"):
            parts.append(character)
        else:
            parts.append(f"_{byte:02x}_")
    return "".join(parts)


def tmux_session_name(area: str, workspace: str) -> str:
    """Return the readable canonical session name for a workspace."""
    return f"{_tmux_name_component(area)}_{_tmux_name_component(workspace)}"


def tmux_session_name_for_path(path: Path) -> str:
    """Return a collision-safe session name for a workspace path."""
    path = path.resolve()
    context = current_workspace_context(path)
    if not context:
        return path.name
    area, workspace = context
    return tmux_session_name(area, workspace)


def kill_tmux_sessions(session_name: str) -> None:
    """Kill the canonical session for a workspace."""
    if shutil.which("tmux") is None:
        return
    result = subprocess.run(
        ["tmux", "list-sessions", "-F", "#{session_name}"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return
    for candidate in result.stdout.splitlines():
        if candidate == session_name:
            subprocess.run(
                ["tmux", "kill-session", "-t", candidate],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )


def kill_tmux_windows_for_path(path: Path) -> None:
    """Kill checkout windows rooted at a path."""
    if shutil.which("tmux") is None:
        return
    result = subprocess.run(
        [
            "tmux",
            "list-windows",
            "-a",
            "-F",
            "#{window_id}\t#{@ws_checkout_path}\t#{pane_current_path}",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return
    target = path.resolve()
    for line in result.stdout.splitlines():
        window_id, saved_path, current_path = line.split("\t", 2)
        window_path = saved_path or current_path
        if window_path and Path(window_path).resolve() == target:
            subprocess.run(
                ["tmux", "kill-window", "-t", window_id],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )


def _checkout_window(session_name: str, path: Path) -> str:
    """Find or create the window for a checkout."""
    result = subprocess.run(
        [
            "tmux",
            "list-windows",
            "-t",
            session_name,
            "-F",
            "#{window_id}\t#{@ws_checkout_path}\t#{pane_current_path}",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    target = path.resolve()
    for line in result.stdout.splitlines():
        window_id, saved_path, current_path = line.split("\t", 2)
        window_path = saved_path or current_path
        if window_path and Path(window_path).resolve() == target:
            return window_id
    result = subprocess.run(
        [
            "tmux",
            "new-window",
            "-d",
            "-t",
            session_name,
            "-c",
            str(target),
            "-n",
            path.name,
            "-P",
            "-F",
            "#{window_id}",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    window_id = result.stdout.strip()
    subprocess.run(
        [
            "tmux",
            "set-option",
            "-w",
            "-t",
            window_id,
            "@ws_checkout_path",
            str(target),
        ],
        check=True,
    )
    return window_id


def open_in_tmux(path: Path, session_name: str):
    """Open a workspace, using one window per checkout."""
    path = path.resolve()
    checkout_path = None
    context = current_workspace_context(path)
    if context:
        area, workspace = context
        workspace_path = (WORKSPACE_DIRS[area] / workspace).resolve()
        relative = path.relative_to(workspace_path)
        if relative.parts:
            checkout_path = workspace_path / relative.parts[0]
        path = workspace_path
        session_name = tmux_session_name(area, workspace)
    in_tmux = os.environ.get("TMUX")
    session_exists = (
        subprocess.run(
            ["tmux", "has-session", "-t", session_name],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode
        == 0
    )

    if not session_exists:
        subprocess.run(
            [
                "tmux",
                "new-session",
                "-ds",
                session_name,
                "-c",
                str(path),
                "-n",
                "workspace",
            ],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    if checkout_path:
        window_id = _checkout_window(session_name, checkout_path)
        subprocess.run(["tmux", "select-window", "-t", window_id], check=True)

    if in_tmux:
        subprocess.run(["tmux", "switch-client", "-t", session_name], check=True)
    else:
        subprocess.run(["tmux", "attach-session", "-t", session_name], check=True)


def get_commit_timestamp(worktree: Path) -> int | None:
    """Get the timestamp of the checkout's latest commit."""
    result = git("log", "-1", "--format=%ct", cwd=worktree)
    if result.returncode != 0 or not result.stdout.strip():
        return None
    try:
        return int(result.stdout.strip())
    except ValueError:
        return None


def get_commit_age_days(worktree: Path) -> int:
    """Get days since last commit, or -1 when unavailable."""
    timestamp = get_commit_timestamp(worktree)
    return int((time.time() - timestamp) / 86400) if timestamp is not None else -1


def get_unpushed_count(worktree: Path) -> int:
    """Count commits ahead of remote tracking branch.

    Returns:
        Number of unpushed commits, or -1 when push safety cannot be verified.
    """
    result = git("rev-list", "@{u}..HEAD", "--count", cwd=worktree)
    if result.returncode != 0:
        branch = git("branch", "--show-current", cwd=worktree)
        if branch.returncode != 0:
            return -1
        if branch.stdout.strip():
            remotes = git(
                "for-each-ref",
                "--format=%(refname)",
                "refs/remotes",
                cwd=worktree,
            )
            if remotes.returncode != 0 or not remotes.stdout.strip():
                return -1
            result = git(
                "rev-list",
                "--count",
                "HEAD",
                "--not",
                *remotes.stdout.split(),
                cwd=worktree,
            )
        else:
            refs = git("for-each-ref", "--format=%(refname)", cwd=worktree)
            if refs.returncode != 0:
                return -1
            args = ["rev-list", "--count", "HEAD"]
            ref_names = refs.stdout.split()
            if ref_names:
                args.extend(["--not", *ref_names])
            result = git(*args, cwd=worktree)
    if result.returncode == 0 and result.stdout.strip():
        try:
            return int(result.stdout.strip())
        except ValueError:
            return -1
    return -1


def add_local_git_exclude(worktree: Path, pattern: str) -> None:
    """Ensure a pattern exists in the worktree's local git exclude."""
    result = git("rev-parse", "--git-path", "info/exclude", cwd=worktree)
    if result.returncode != 0:
        return

    exclude_path = Path(result.stdout.strip())
    if not exclude_path.is_absolute():
        exclude_path = worktree / exclude_path

    try:
        existing = exclude_path.read_text()
    except FileNotFoundError:
        existing = ""

    lines = [line.strip() for line in existing.splitlines()]
    if pattern in lines:
        return

    if existing and not existing.endswith("\n"):
        existing += "\n"
    existing += f"{pattern}\n"

    exclude_path.parent.mkdir(parents=True, exist_ok=True)
    exclude_path.write_text(existing)


def style_age(age_str: str, days: int, stale_threshold: int = 7) -> str:
    """Color-code age string based on staleness.

    Args:
        age_str: Human-readable age string (e.g., "2 days ago")
        days: Number of days since last commit
        stale_threshold: Days threshold for "stale" (default: 7)

    Returns:
        Rich-formatted string with appropriate color.
    """
    if days < 0:
        return f"[dim]{age_str}[/dim]"
    elif days <= stale_threshold:
        return f"[green]{age_str}[/green]"
    elif days <= stale_threshold * 2:
        return f"[yellow]{age_str}[/yellow]"
    else:
        return f"[red]{age_str}[/red]"


def get_status_symbol(has_changes: bool, unpushed: int, is_stale: bool) -> str:
    """Get status symbol for workspace display.

    Returns:
        Symbol string: ✓ (clean), ● (modified), ↑ (unpushed), ? (unknown), ⚠ (stale)
        Multiple symbols combined if multiple conditions apply.
    """
    symbols = []
    if has_changes:
        symbols.append("●")
    if unpushed > 0:
        symbols.append("↑")
    elif unpushed < 0:
        symbols.append("?")
    if is_stale:
        symbols.append("⚠")
    if not symbols:
        symbols.append("✓")
    return "".join(symbols)


def get_branches(
    repo: Path,
) -> list[str]:
    """Get all branches from a repository."""
    result = git("branch", "-a", cwd=repo)
    if result.returncode != 0:
        return []

    branches = []
    for line in result.stdout.strip().split("\n"):
        branch = line.strip().lstrip("* ")
        if branch.startswith("remotes/origin/"):
            branch = branch.replace("remotes/origin/", "")
        branches.append(branch)

    # Deduplicate and sort
    branches = sorted(set(branches))
    return branches


def resolve_repository(value: str | None) -> Path | None:
    """Resolve an exact path or repository name, prompting only when omitted."""
    if value is None:
        return pick_repo()
    candidate = Path(value).expanduser()
    if candidate.exists():
        return candidate.resolve()
    matches = [repo for repo in get_all_repos() if repo.name.casefold() == value.casefold()]
    if len(matches) == 1:
        return matches[0]
    if not matches:
        raise ValueError(f"Repository not found: {value}")
    raise ValueError(f"Repository name is ambiguous: {value}")


def current_workspace_context(start: Path | None = None) -> tuple[str, str] | None:
    """Detect the containing workspace from its root or a child checkout."""
    current = (start or Path.cwd()).resolve()
    for area, root in WORKSPACE_DIRS.items():
        root = root.resolve()
        try:
            relative = current.relative_to(root)
        except ValueError:
            continue
        if relative.parts:
            return area, relative.parts[0]
    return None


def pick_checkout_spec(repo: Path) -> tuple[str, str, str | None]:
    """Prompt for a safe checkout mode and source ref."""
    choice = cast(
        str | None,
        iterfzf(
            ["Detached checkout", "Existing branch", "New branch"],
            prompt="Checkout mode: ",
            exact=True,
        ),
    )
    if choice == "Detached checkout":
        ref = Prompt.ask("[cyan]Source ref[/cyan]", default="HEAD")
        return "detach", ref, None
    if choice == "New branch":
        branch = Prompt.ask("[cyan]New branch name[/cyan]")
        ref = Prompt.ask("[cyan]Start point[/cyan]", default="HEAD")
        return "new", ref, branch
    if choice == "Existing branch":
        branch = cast(
            str | None,
            iterfzf(
                get_branches(repo),
                prompt="Existing branch: ",
                exact=True,
                extended=True,
            ),
        )
        if branch:
            return "existing", branch, None
    raise ValueError("No checkout mode selected")


def _add_worktree(
    area: Optional[str],
    workspace: Optional[str],
    repo: Optional[str],
    branch: Optional[str],
    custom_name: Optional[str],
    *,
    ref: str | None = None,
    detach: bool = False,
    new_branch: str | None = None,
    role: str | None = None,
    ephemeral: bool = False,
    json_output: bool = False,
):
    """Resolve interactive CLI arguments and add a checkout."""
    interactive_spec = not any((branch, ref, detach, new_branch))
    context = current_workspace_context()
    if context:
        area = area or context[0]
        workspace = workspace or context[1]
    if not area:
        area = pick_area()
        if not area:
            raise ValueError("No area selected")
    if not workspace:
        workspace = pick_workspace(area)
        if not workspace:
            raise ValueError("No workspace selected")

    repo_path = resolve_repository(repo)
    if not repo_path:
        raise ValueError("No repository selected")

    if new_branch:
        mode = "new"
        source_ref = ref or branch or "HEAD"
    elif detach:
        mode = "detach"
        source_ref = ref or branch or "HEAD"
    elif ref or branch:
        mode = "existing"
        source_ref = ref or cast(str, branch)
    else:
        mode, source_ref, new_branch = pick_checkout_spec(repo_path)

    if role is None:
        role = "control" if mode == "detach" else "development"
    if interactive_spec:
        role = Prompt.ask("[cyan]Checkout role[/cyan]", default=role)
        if custom_name is None:
            custom_name = Prompt.ask(
                "[cyan]Checkout name[/cyan]",
                default=f"{repo_path.name}-{role}",
            )

    target = add_checkout(
        area,
        workspace,
        repo_path,
        ref=source_ref,
        mode=mode,
        new_branch=new_branch,
        name=custom_name,
        role=role,
        ephemeral=ephemeral,
    )
    if json_output:
        console.print_json(
            data={
                "area": area,
                "workspace": workspace,
                "path": str(target),
                "repo": str(repo_path),
                "ref": source_ref,
                "mode": mode,
                "role": role,
                "ephemeral": ephemeral,
            }
        )
    else:
        console.print(f"[green]Added checkout:[/green] [cyan]{target}[/cyan]")


@workspace_app.command("create")
def workspace_create(
    area: Optional[str] = typer.Argument(
        None,
        help="Area: 'personal' or 'work'",
    ),
    name: Optional[str] = typer.Argument(
        None,
        help="Workspace name (e.g., TICKET-123)",
    ),
    description: Optional[str] = typer.Argument(
        None,
        help="Optional description",
    ),
):
    """Create an empty orchestration workspace."""
    if not area:
        area = pick_area()
        if not area:
            console.print("[red]No area selected[/red]")
            raise typer.Exit(1)
    if not name:
        name = Prompt.ask("[cyan]Workspace name (e.g., TICKET-123)[/cyan]")
        if not name:
            console.print("[red]No name provided[/red]")
            raise typer.Exit(1)
    if description is None:
        description = Prompt.ask(
            "[cyan]Description (optional)[/cyan]",
            default="",
        )
    try:
        workspace_path = create_workspace_record(area, name, description)
    except (ValueError, RuntimeError, OSError) as exc:
        console.print(f"[red]{exc}[/red]")
        raise typer.Exit(1) from exc
    console.print(f"[green]Created workspace:[/green] [cyan]{workspace_path}[/cyan]")
    if Confirm.ask("[cyan]Add a worktree to this workspace now?[/cyan]"):
        try:
            _add_worktree(
                area=area,
                workspace=name,
                repo=None,
                branch=None,
                custom_name=None,
            )
        except (ValueError, RuntimeError, OSError) as exc:
            console.print(f"[red]{exc}[/red]")
            raise typer.Exit(1) from exc


@worktree_app.command("add")
def worktree_add(
    area: Optional[str] = typer.Argument(
        None,
        help="Area: 'personal' or 'work'",
    ),
    workspace: Optional[str] = typer.Argument(None, help="Workspace name"),
    repo: Optional[str] = typer.Argument(None, help="Repository name"),
    branch: Optional[str] = typer.Argument(None, help="Existing branch or source ref"),
    repo_path: Optional[str] = typer.Option(
        None,
        "--repo-path",
        help="Exact repository path; useful for non-interactive agents",
    ),
    name: Optional[str] = typer.Option(
        None,
        "--name",
        "-n",
        help="Custom checkout folder name",
    ),
    ref: Optional[str] = typer.Option(
        None,
        "--ref",
        help="Source ref or start point",
    ),
    detach: bool = typer.Option(
        False,
        "--detach",
        help="Create a detached checkout",
    ),
    new_branch: Optional[str] = typer.Option(
        None,
        "--new-branch",
        "-b",
        help="Create this branch at --ref (or HEAD)",
    ),
    role: Optional[str] = typer.Option(
        None,
        "--role",
        help="Checkout role (defaults to control when detached, otherwise development)",
    ),
    ephemeral: bool = typer.Option(
        False,
        "--ephemeral",
        help="Mark the checkout as disposable",
    ),
    json_output: bool = typer.Option(
        False,
        "--json",
        help="Emit machine-readable checkout metadata",
    ),
):
    """Add a detached, existing-branch, or new-branch checkout."""
    if detach and new_branch:
        console.print("[red]--detach and --new-branch cannot be combined[/red]")
        raise typer.Exit(2)
    if repo and repo_path:
        console.print("[red]Pass either the repository argument or --repo-path, not both[/red]")
        raise typer.Exit(2)
    try:
        _add_worktree(
            area=area,
            workspace=workspace,
            repo=repo_path or repo,
            branch=branch,
            custom_name=name,
            ref=ref,
            detach=detach,
            new_branch=new_branch,
            role=role,
            ephemeral=ephemeral,
            json_output=json_output,
        )
    except (ValueError, RuntimeError, OSError) as exc:
        console.print(f"[red]{exc}[/red]")
        raise typer.Exit(1) from exc


@worktree_app.command("list")
def worktree_list(
    area: Optional[str] = typer.Argument(
        None,
        help="Area: 'personal' or 'work'",
    ),
    workspace: Optional[str] = typer.Argument(None, help="Workspace name"),
    json_output: bool = typer.Option(
        False,
        "--json",
        help="Emit machine-readable checkout metadata",
    ),
):
    """List all checkouts in a workspace."""
    if not area:
        area = pick_area()
        if not area:
            console.print("[red]No area selected[/red]")
            raise typer.Exit(1)
    if not workspace:
        workspace = pick_workspace(area)
        if not workspace:
            console.print("[red]No workspace selected or none exist[/red]")
            raise typer.Exit(1)
    try:
        summary = next(item for item in scan_workspaces() if item.area == area and item.name == workspace)
    except StopIteration:
        console.print(f"[red]Workspace not found: {area}/{workspace}[/red]")
        raise typer.Exit(1) from None
    except (RuntimeError, OSError) as exc:
        console.print(f"[red]{exc}[/red]")
        raise typer.Exit(1) from exc

    if json_output:
        console.print_json(
            data={
                "area": summary.area,
                "workspace": summary.name,
                "path": str(summary.path),
                "description": summary.description,
                "checkouts": [
                    {
                        **asdict(checkout),
                        "path": str(checkout.path),
                        "repo": str(checkout.repo),
                    }
                    for checkout in summary.checkouts
                ],
            }
        )
        return
    if not summary.checkouts:
        console.print(f"[yellow]No checkouts found in workspace {workspace}[/yellow]")
        return

    table = Table(title=f"Checkouts in {area}/{workspace}")
    table.add_column("Name", style="cyan")
    table.add_column("Role", style="magenta")
    table.add_column("Mode")
    table.add_column("Ref", style="blue")
    table.add_column("Branch", style="yellow")
    table.add_column("Status")
    for checkout in summary.checkouts:
        status = "[red]modified[/red]" if checkout.dirty else "[green]clean[/green]"
        if checkout.unpushed > 0:
            status += f" [yellow]up {checkout.unpushed}[/yellow]"
        elif checkout.unpushed < 0:
            status += " [yellow]push unknown[/yellow]"
        table.add_row(
            checkout.name,
            checkout.role,
            checkout.mode,
            checkout.ref,
            checkout.branch,
            status,
        )
    console.print(table)


@worktree_app.command("remove")
def worktree_remove(
    area: Optional[str] = typer.Argument(
        None,
        help="Area: 'personal' or 'work'",
    ),
    workspace: Optional[str] = typer.Argument(None, help="Workspace name"),
    worktree: Optional[str] = typer.Argument(None, help="Worktree to remove"),
    force: bool = typer.Option(
        False,
        "--force",
        "-f",
        help="Skip confirmation",
    ),
):
    """Safely remove a checkout from a workspace."""
    if not area:
        area = pick_area()
        if not area:
            console.print("[red]No area selected[/red]")
            raise typer.Exit(1)
    if not workspace:
        workspace = pick_workspace(area)
        if not workspace:
            console.print("[red]No workspace selected or none exist[/red]")
            raise typer.Exit(1)
    try:
        workspace = _validate_name(workspace, "Workspace name")
    except ValueError as exc:
        console.print(f"[red]{exc}[/red]")
        raise typer.Exit(2) from exc
    ws_path = WORKSPACE_DIRS[area] / workspace
    if not ws_path.exists():
        console.print(f"[red]Workspace not found: {ws_path}[/red]")
        raise typer.Exit(1)
    worktrees = [w for w in ws_path.iterdir() if (w / ".git").exists()]
    if not worktrees:
        console.print(f"[yellow]No checkouts found in workspace {workspace}[/yellow]")
        raise typer.Exit(1)
    if not worktree:
        worktree_names = [w.name for w in worktrees]
        selected = cast(
            Optional[str],
            iterfzf(
                worktree_names,
                prompt="Select worktree to remove: ",
                exact=True,
                extended=True,
            ),
        )
        if not selected:
            console.print("[red]No checkout selected[/red]")
            raise typer.Exit(1)
        worktree = selected
    try:
        worktree = _validate_name(worktree, "Checkout name")
    except ValueError as exc:
        console.print(f"[red]{exc}[/red]")
        raise typer.Exit(2) from exc
    worktree_path = ws_path / worktree
    if not worktree_path.exists() or not (worktree_path / ".git").exists():
        console.print(f"[red]Checkout not found: {worktree_path}[/red]")
        raise typer.Exit(1)
    if not force:
        console.print(f"[yellow]This will remove checkout: {worktree_path}[/yellow]")
        if not Confirm.ask("Continue?"):
            raise typer.Abort()
    try:
        remove_checkout(worktree_path, force=force)
    except (ValueError, RuntimeError, OSError) as exc:
        console.print(f"[red]{exc}[/red]")
        if not force:
            console.print("[dim]Inspect the checkout, or repeat with --force if loss is intended.[/dim]")
        raise typer.Exit(1) from exc
    console.print(f"[green]Removed checkout:[/green] [cyan]{worktree}[/cyan]")


@workspace_app.command("list")
def workspace_list():
    """List all workspaces and their worktrees."""
    has_any = False
    for (
        area,
        root,
    ) in WORKSPACE_DIRS.items():
        if root.exists() and any(root.iterdir()):
            has_any = True
            table = Table(
                title=f"{area.upper()} Workspaces",
                show_header=False,
            )
            table.add_column(
                "Workspace",
                style="cyan",
            )
            table.add_column(
                "Worktrees",
                style="green",
            )

            for ws in sorted(root.iterdir()):
                if ws.is_dir():
                    worktrees = [w.name for w in ws.iterdir() if (w / ".git").exists()]
                    table.add_row(
                        ws.name,
                        ", ".join(worktrees) if worktrees else "[dim]empty[/dim]",
                    )

            console.print(table)

    if not has_any:
        console.print("[dim]No workspaces found[/dim]")


@workspace_app.command("remove")
def workspace_remove(
    area: Optional[str] = typer.Argument(
        None,
        help="Area: 'personal' or 'work'",
    ),
    workspace: Optional[str] = typer.Argument(None, help="Workspace to close"),
    force: bool = typer.Option(
        False,
        "--force",
        "-f",
        help="Skip confirmation",
    ),
):
    """Remove a workspace after checking every checkout is safe."""
    if not area:
        area = pick_area()
        if not area:
            console.print("[red]No area selected[/red]")
            raise typer.Exit(1)
    if not workspace:
        workspace = pick_workspace(area)
        if not workspace:
            console.print("[red]No workspace selected or none exist[/red]")
            raise typer.Exit(1)
    ws_path = WORKSPACE_DIRS[area] / workspace
    if not ws_path.exists():
        console.print(f"[red]Workspace not found: {ws_path}[/red]")
        raise typer.Exit(1)
    worktrees = [w for w in ws_path.iterdir() if (w / ".git").exists()]
    if not force:
        console.print(f"[yellow]This will remove {len(worktrees)} checkout(s) and the workspace.[/yellow]")
        if not Confirm.ask("Continue?"):
            raise typer.Abort()
    try:
        remove_workspace_record(area, workspace, force=force)
    except (ValueError, RuntimeError, OSError, subprocess.CalledProcessError) as exc:
        console.print(f"[red]{exc}[/red]")
        if not force:
            console.print("[dim]Inspect unsafe checkouts, or repeat with --force if loss is intended.[/dim]")
        raise typer.Exit(1) from exc
    console.print(f"[green]Removed workspace:[/green] [cyan]{workspace}[/cyan]")


@workspace_app.command("status")
def workspace_status(
    verbose: bool = typer.Option(
        False,
        "--verbose",
        "-v",
        help="Show all workspaces (not just those with changes)",
    ),
    stale: bool = typer.Option(
        False,
        "--stale",
        "-s",
        help="Highlight stale workspaces (no commits in N days)",
    ),
    unpushed: bool = typer.Option(
        False,
        "--unpushed",
        "-u",
        help="Show workspaces with unpushed commits",
    ),
    days: int = typer.Option(
        7,
        "--days",
        "-d",
        help="Staleness threshold in days (default: 7)",
    ),
):
    """Show git status for all workspaces (end-of-day summary)."""
    if verbose or stale or unpushed:
        # Table mode - show detailed table with worktree-level information
        for area, root in WORKSPACE_DIRS.items():
            if not root.exists():
                continue

            all_worktree_data = []
            for ws in sorted(root.iterdir()):
                if ws.is_dir():
                    for worktree in ws.iterdir():
                        if (worktree / ".git").exists():
                            # Extract parent repo from folder name
                            parent_repo = "unknown"
                            folder_name = worktree.name

                            # Try to parse from folder name
                            for base in [
                                Path("~/projects/personal").expanduser(),
                                Path("~/projects/work").expanduser(),
                            ]:
                                if base.exists():
                                    for repo in base.iterdir():
                                        if repo.is_dir() and folder_name.startswith(repo.name):
                                            parent_repo = repo.name
                                            break
                                if parent_repo != "unknown":
                                    break

                            # If still unknown, try git remote
                            if parent_repo == "unknown":
                                result = git("remote", "get-url", "origin", cwd=worktree)
                                if result.returncode == 0 and result.stdout.strip():
                                    remote = result.stdout.strip()
                                    if "/" in remote:
                                        parent_repo = remote.split("/")[-1].replace(".git", "")
                                    else:
                                        parent_repo = remote

                            branch = _checkout_branch(worktree)

                            # Check for changes
                            status_result = git("status", "--short", cwd=worktree)
                            has_changes = bool(status_result.stdout.strip())
                            changes_count = (
                                len(status_result.stdout.strip().split("\n")) if status_result.stdout.strip() else 0
                            )

                            # Get last commit time (human readable)
                            log_result = git("log", "-1", "--format=%ar", cwd=worktree)
                            last_commit = (
                                log_result.stdout.strip()
                                if log_result.returncode == 0 and log_result.stdout.strip()
                                else "no commits"
                            )

                            # Get age in days
                            age_days = get_commit_age_days(worktree)

                            # Get unpushed count
                            unpushed_count = get_unpushed_count(worktree)

                            # Determine if stale
                            is_stale = age_days >= days if age_days >= 0 else False

                            # Filter based on flags
                            if stale and not is_stale:
                                continue
                            if unpushed and unpushed_count == 0:
                                continue

                            all_worktree_data.append(
                                {
                                    "workspace": ws.name,
                                    "parent_repo": parent_repo,
                                    "branch": branch,
                                    "has_changes": has_changes,
                                    "changes_count": changes_count,
                                    "last_commit": last_commit,
                                    "age_days": age_days,
                                    "unpushed": unpushed_count,
                                    "is_stale": is_stale,
                                    "worktree_name": worktree.name,
                                }
                            )

            if all_worktree_data:
                # Sort: stale first if using --stale flag
                if stale:
                    all_worktree_data.sort(key=lambda x: (-x["age_days"], x["workspace"]))

                table = Table(
                    title=f"{area.upper()} Workspaces",
                    show_header=True,
                )
                table.add_column("", style="white", width=3)  # Status symbols
                table.add_column("Workspace", style="cyan")
                table.add_column("Repository", style="magenta")
                table.add_column("Branch", style="yellow")
                table.add_column("Status", style="white")
                table.add_column("Last Commit", style="white")

                for data in all_worktree_data:
                    # Build status symbol
                    symbol = get_status_symbol(data["has_changes"], data["unpushed"], data["is_stale"])

                    # Build status text
                    status_parts = []
                    if data["has_changes"]:
                        status_parts.append(f"[red]{data['changes_count']} files[/red]")
                    else:
                        status_parts.append("[dim]clean[/dim]")

                    if data["unpushed"] > 0:
                        status_parts.append(f"[yellow]↑{data['unpushed']}[/yellow]")
                    elif data["unpushed"] < 0:
                        status_parts.append("[yellow]push unknown[/yellow]")

                    status_text = " ".join(status_parts)

                    # Color-code last commit by age
                    last_commit_styled = style_age(data["last_commit"], data["age_days"], days)

                    table.add_row(
                        symbol,
                        data["workspace"],
                        data["parent_repo"],
                        data["branch"],
                        status_text,
                        last_commit_styled,
                    )

                console.print(table)
                console.print()
            elif stale or unpushed:
                # User filtered but nothing matched
                filter_desc = []
                if stale:
                    filter_desc.append(f"stale (>{days}d)")
                if unpushed:
                    filter_desc.append("unpushed")
                console.print(f"[dim]No {' or '.join(filter_desc)} workspaces found in {area}[/dim]")
    else:
        # Default mode - show only workspaces with changes
        has_changes = False

        for (
            area,
            root,
        ) in WORKSPACE_DIRS.items():
            if root.exists():
                for ws in sorted(root.iterdir()):
                    if ws.is_dir():
                        workspace_has_changes = False
                        statuses = []

                        for worktree in sorted(ws.iterdir()):
                            if (worktree / ".git").exists():
                                result = git(
                                    "status",
                                    "--short",
                                    cwd=worktree,
                                )
                                if result.stdout.strip():
                                    workspace_has_changes = True
                                    has_changes = True
                                    statuses.append(
                                        (
                                            worktree.name,
                                            result.stdout.strip(),
                                        )
                                    )

                        if workspace_has_changes:
                            console.print(f"\n[bold cyan]{area}/{ws.name}[/bold cyan]")
                            for (
                                name,
                                status,
                            ) in statuses:
                                console.print(f"  [yellow]{name}:[/yellow]")
                                for line in status.split("\n"):
                                    console.print(f"    {line}")

        if not has_changes:
            console.print("[green]✓ All workspaces are clean[/green]")


@worktree_app.command("git")
def worktree_git():
    """Open lazygit - in current repo or pick from workspace worktrees."""
    current_dir = Path.cwd()

    # Check if we're in a workspace folder (contains worktrees)
    workspace_path = None

    # Quick check: if current directory contains .workspaces in the path
    current_str = str(current_dir)
    if ".workspaces" in current_str:
        # We're likely in a workspace, find the workspace folder
        for part in current_dir.parts:
            if part.endswith(".workspaces"):
                # Found the workspace parent, now find our workspace folder
                idx = current_dir.parts.index(part)
                if idx < len(current_dir.parts) - 1:
                    # Reconstruct path up to workspace folder
                    workspace_path = Path(*current_dir.parts[: idx + 2])
                    break

    if workspace_path and workspace_path.exists():
        # We're in a workspace - show picker of worktrees
        worktrees = []
        for item in workspace_path.iterdir():
            if item.is_dir() and (item / ".git").exists():
                # Just use the folder name initially, don't call git yet
                worktrees.append((item.name, item))

        if not worktrees:
            console.print("[red]No worktrees found in workspace[/red]")
            raise typer.Exit(1)

        if len(worktrees) == 1:
            # Only one worktree, use it directly
            selected_path = worktrees[0][1]
        else:
            # Show picker with just folder names (much faster)
            display_names = [name for name, _ in worktrees]
            selected_display = cast(
                Optional[str],
                iterfzf(
                    display_names,
                    prompt="Select worktree for lazygit: ",
                    exact=True,
                    extended=True,
                ),
            )

            if not selected_display:
                console.print("[red]No worktree selected[/red]")
                raise typer.Exit(1)

            # Find the matching path
            selected_path = None
            for (
                name,
                path,
            ) in worktrees:
                if name == selected_display:
                    selected_path = path
                    break

        console.print(f"[green]Opening lazygit in:[/green] [cyan]{selected_path}[/cyan]")
        subprocess.run(
            [
                "lazygit",
                "-p",
                str(selected_path),
            ]
        )
    else:
        # We're in a regular repo (or not in a git repo at all) - just run lazygit
        console.print(f"[green]Opening lazygit in current directory:[/green] [cyan]{current_dir}[/cyan]")
        subprocess.run(["lazygit"])


@workspace_app.command("open")
def workspace_open(
    target: Optional[str] = typer.Argument(
        None,
        help="Specific path, workspace, or repo to open",
    ),
    all: bool = typer.Option(
        False,
        "--all",
        "-a",
        help="Show all directories (repos + workspaces)",
    ),
    checkout: Optional[str] = typer.Option(
        None,
        "--checkout",
        "-c",
        help="Open this checkout instead of the workspace root",
    ),
):
    """Open a workspace or repository in tmux session (replacement for 'ta')."""

    if target:
        if checkout:
            try:
                checkout = _validate_name(checkout, "Checkout name")
            except ValueError as exc:
                console.print(f"[red]{exc}[/red]")
                raise typer.Exit(2) from exc
        # If a specific target is provided, try to open it directly
        target_path = Path(target).expanduser()
        if target_path.exists() and target_path.is_dir():
            if checkout:
                target_path = target_path / checkout
                if not target_path.is_dir() or not (target_path / ".git").exists():
                    console.print(f"[red]Checkout not found: {target_path}[/red]")
                    raise typer.Exit(1)
            session_name = tmux_session_name_for_path(target_path)
            console.print(f"[green]Opening in tmux:[/green] [cyan]{target_path}[/cyan]")
            open_in_tmux(
                target_path,
                session_name,
            )
            return

        # Try to find it as a workspace
        for (
            area,
            ws_dir,
        ) in WORKSPACE_DIRS.items():
            ws_path = ws_dir / target
            if ws_path.exists():
                open_path = ws_path
                session_name = tmux_session_name(area, target)
                if checkout:
                    open_path = ws_path / checkout
                    if not open_path.is_dir() or not (open_path / ".git").exists():
                        console.print(f"[red]Checkout not found: {open_path}[/red]")
                        raise typer.Exit(1)
                    session_name = tmux_session_name(area, target)
                console.print(f"[green]Opening in tmux:[/green] [cyan]{open_path}[/cyan]")
                open_in_tmux(
                    open_path,
                    session_name,
                )
                return

        console.print(f"[red]✗ Directory not found: {target}[/red]")
        raise typer.Exit(1)

    # Interactive selection mode
    if all:
        # Show all directories (repos + workspaces)
        all_dirs = get_all_directories()
        if not all_dirs:
            console.print("[red]No directories found[/red]")
            raise typer.Exit(1)

        # Show relative paths for better context
        display_paths = [path_str for path_str, _ in all_dirs]

        selected = cast(
            Optional[str],
            iterfzf(
                display_paths,
                prompt="Select directory to open: ",
                exact=True,  # Enable exact matching
                extended=True,  # Enable extended search mode
            ),
        )

        if not selected:
            console.print("[red]No directory selected[/red]")
            raise typer.Exit(1)

        # Find the matching path
        for path_str, path_obj in all_dirs:
            if path_str == selected:
                session_name = path_obj.name
                if "workspaces" in str(path_obj):
                    # For workspaces, include parent dir in session name
                    parent = path_obj.parent.name.replace(
                        ".workspaces",
                        "",
                    )
                    session_name = tmux_session_name(parent, path_obj.name)
                console.print(f"[green]Opening in tmux:[/green] [cyan]{path_obj}[/cyan]")
                open_in_tmux(
                    path_obj,
                    session_name,
                )
                return
    else:
        # Show only workspaces by default
        all_workspaces = get_all_workspaces()
        if not all_workspaces:
            console.print("[red]No workspaces found[/red]")
            console.print("[dim]Tip: Use --all to see repositories too[/dim]")
            raise typer.Exit(1)

        # Show full paths for workspaces
        # Show relative paths for workspaces
        display_paths = [path_str for path_str, _ in all_workspaces]

        selected = cast(
            Optional[str],
            iterfzf(
                display_paths,
                prompt="Select workspace to open: ",
                exact=True,
                extended=True,
            ),
        )

        if not selected:
            console.print("[red]No workspace selected[/red]")
            raise typer.Exit(1)

        # Find the matching workspace
        for path_str, path_obj in all_workspaces:
            if path_str == selected:
                parent = path_obj.parent.name.replace(".workspaces", "")
                session_name = tmux_session_name(parent, path_obj.name)
                console.print(f"[green]Opening workspace in tmux:[/green] [cyan]{path_obj}[/cyan]")
                open_in_tmux(
                    path_obj,
                    session_name,
                )
                return


# Top-level convenience commands
@app.command("stats")
def stats_command(
    json_output: bool = typer.Option(
        False,
        "--json",
        help="Emit machine-readable workspace statistics",
    ),
    stale_days: int = typer.Option(
        7,
        "--stale-days",
        min=1,
        help="Age in days that marks a checkout stale",
    ),
):
    """Show activity, safety, and change statistics for workspaces."""
    report = stats_report(stale_days)
    if json_output:
        console.print_json(data=report)
        return

    totals = report["totals"]
    summary = Table(title="Workspace Overview", show_header=False)
    summary.add_column("Metric", style="cyan")
    summary.add_column("Value", style="bold")
    summary.add_row("Workspaces", str(totals["workspaces"]))
    summary.add_row("Checkouts", str(totals["checkouts"]))
    summary.add_row("Repositories", str(totals["repositories"]))
    summary.add_row(
        "Roles",
        ", ".join(f"{name} {count}" for name, count in totals["roles"].items()) or "none",
    )
    summary.add_row(
        "Modes",
        ", ".join(f"{name} {count}" for name, count in totals["modes"].items()) or "none",
    )
    console.print(summary)

    table = Table(title="Workspace Activity")
    table.add_column("Workspace", style="cyan")
    table.add_column("Checkouts", justify="right")
    table.add_column("Repos", justify="right")
    table.add_column("Dirty", justify="right")
    table.add_column("Files", justify="right")
    table.add_column("Ahead", justify="right")
    table.add_column("Unknown", justify="right")
    table.add_column("Stale", justify="right")
    table.add_column("Last activity", justify="right")
    for row in report["workspaces"]:
        age = row["age_days"]
        activity = "unknown" if age < 0 else ("today" if age == 0 else f"{age}d ago")
        table.add_row(
            f"{row['area']}/{row['name']}",
            str(row["checkouts"]),
            str(row["repositories"]),
            str(row["dirty_checkouts"]),
            str(row["changed_files"]),
            str(row["unpushed_commits"]),
            str(row["unknown_push_state"]),
            str(row["stale_checkouts"]),
            activity,
        )
    console.print(table)


@app.command("list")
def list_all():
    """List all workspaces and their worktrees (alias for 'workspace list')."""
    workspace_list()


@app.command("status")
def status(
    verbose: bool = typer.Option(
        False,
        "--verbose",
        "-v",
        help="Show all workspaces (not just those with changes)",
    ),
    stale: bool = typer.Option(
        False,
        "--stale",
        "-s",
        help="Highlight stale workspaces (no commits in N days)",
    ),
    unpushed: bool = typer.Option(
        False,
        "--unpushed",
        "-u",
        help="Show workspaces with unpushed commits",
    ),
    days: int = typer.Option(
        7,
        "--days",
        "-d",
        help="Staleness threshold in days (default: 7)",
    ),
):
    """Show git status for all workspaces (alias for 'workspace status')."""
    workspace_status(verbose=verbose, stale=stale, unpushed=unpushed, days=days)


@app.command("open")
def open(
    target: Optional[str] = typer.Argument(
        None,
        help="Specific path, workspace, or repo to open",
    ),
    all: bool = typer.Option(
        False,
        "--all",
        "-a",
        help="Show all directories (repos + workspaces)",
    ),
    checkout: Optional[str] = typer.Option(
        None,
        "--checkout",
        "-c",
        help="Open this checkout instead of the workspace root",
    ),
):
    """Quick open a workspace or repository in tmux (alias for 'workspace open')."""
    workspace_open(target=target, all=all, checkout=checkout)


@app.command("create")
def create(
    area: Optional[str] = typer.Argument(
        None,
        help="Area: 'personal' or 'work'",
    ),
    name: Optional[str] = typer.Argument(
        None,
        help="Workspace name (e.g., TICKET-123)",
    ),
    description: Optional[str] = typer.Argument(
        None,
        help="Optional description",
    ),
):
    """Quick create a new workspace (alias for 'workspace create')."""
    workspace_create(area=area, name=name, description=description)


@app.command("tui")
def tui():
    """Open the interactive workspace manager."""
    from ws_tui import run_tui

    run_tui()


if __name__ == "__main__":
    app()
