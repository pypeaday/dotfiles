# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "rich",
# ]
# ///
"""Meaningless git statistics for the current repository."""

from __future__ import annotations

import argparse
import subprocess
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from rich import box
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.text import Text


@dataclass(frozen=True)
class LineCount:
    total_lines: int
    files_counted: int
    skipped_binary: int
    skipped_missing: int
    by_category: dict[str, int]


@dataclass(frozen=True)
class AuthorLines:
    added: int
    deleted: int
    files_changed: int
    skipped_binary: int
    added_by_category: dict[str, int]
    deleted_by_category: dict[str, int]
    files_changed_by_category: dict[str, int]


console = Console()
err_console = Console(stderr=True)
FILE_CATEGORIES = ("code", "docs", "config", "other")
DOC_SUFFIXES = {".md", ".txt", ".rst", ".adoc"}
DOC_NAMES = {"license", "copying", "notice", "readme"}
CONFIG_SUFFIXES = {
    ".yaml",
    ".yml",
    ".json",
    ".jsonc",
    ".toml",
    ".conf",
    ".cfg",
    ".ini",
    ".ron",
    ".service",
    ".timer",
    ".local",
    ".code-profile",
    ".kksrc",
    ".properties",
    ".example",
}
CONFIG_NAMES = {
    "config",
    ".gitignore",
    ".gitconfig",
    ".zshrc",
    ".zprofile",
    ".bashrc",
    ".bash_profile",
    ".profile",
    ".tool-versions",
}
CODE_SUFFIXES = {
    ".py",
    ".sh",
    ".bash",
    ".zsh",
    ".awk",
    ".lua",
    ".css",
    ".scss",
    ".js",
    ".jsx",
    ".ts",
    ".tsx",
    ".go",
    ".rs",
    ".java",
    ".c",
    ".h",
    ".cpp",
    ".hpp",
    ".jinja",
    ".snippets",
}


def categorize_path(path: Path) -> str:
    suffix = path.suffix.lower()
    name = path.name.lower()
    parts = {part.lower() for part in path.parts}
    if suffix in DOC_SUFFIXES or name in DOC_NAMES:
        return "docs"
    if suffix in CONFIG_SUFFIXES or name in CONFIG_NAMES or ".config" in parts:
        return "config"
    if suffix in CODE_SUFFIXES:
        return "code"
    if suffix:
        return "other"
    return "code"


def run_git(args: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        text=True,
        capture_output=True,
    )


def get_repo_root(start: Path) -> Path:
    result = run_git(["rev-parse", "--show-toplevel"], cwd=start)
    if result.returncode != 0:
        raise RuntimeError("Not inside a git repository.")
    return Path(result.stdout.strip())


def get_git_user(repo: Path) -> str | None:
    for key in ("user.name", "user.email"):
        result = run_git(["config", "--get", key], cwd=repo)
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    return None


def get_commit_count(repo: Path, author: str | None = None) -> int:
    args = ["rev-list", "--count", "HEAD"]
    if author:
        args = ["rev-list", "--count", f"--author={author}", "HEAD"]
    result = run_git(args, cwd=repo)
    if result.returncode != 0 or not result.stdout.strip():
        return 0
    try:
        return int(result.stdout.strip())
    except ValueError:
        return 0


def get_top_authors(repo: Path, limit: int = 3) -> list[tuple[str, int]]:
    result = run_git(["shortlog", "-s", "-n", "HEAD"], cwd=repo)
    if result.returncode != 0:
        return []
    authors: list[tuple[str, int]] = []
    for line in result.stdout.splitlines():
        if not line.strip():
            continue
        parts = line.strip().split("\t", 1)
        if len(parts) != 2:
            continue
        count_raw, name = parts
        try:
            count = int(count_raw.strip())
        except ValueError:
            continue
        authors.append((name.strip(), count))
        if len(authors) >= limit:
            break
    return authors


def iter_tracked_files(repo: Path) -> Iterable[Path]:
    result = run_git(["ls-files", "-z"], cwd=repo)
    if result.returncode != 0:
        return []
    files = [f for f in result.stdout.split("\0") if f]
    return (repo / f for f in files)


def count_lines_in_file(path: Path) -> int | None:
    try:
        with path.open("rb") as handle:
            first = handle.read(8192)
            if b"\0" in first:
                return None
            if not first:
                return 0
            lines = first.count(b"\n")
            last_byte = first[-1:]
            for chunk in iter(lambda: handle.read(8192), b""):
                lines += chunk.count(b"\n")
                last_byte = chunk[-1:]
            if last_byte != b"\n":
                lines += 1
            return lines
    except FileNotFoundError:
        return None


def count_repo_lines(repo: Path) -> LineCount:
    total_lines = 0
    files_counted = 0
    skipped_binary = 0
    skipped_missing = 0
    by_category: dict[str, int] = defaultdict(int)
    for file_path in iter_tracked_files(repo):
        result = count_lines_in_file(file_path)
        if result is None:
            if file_path.exists():
                skipped_binary += 1
            else:
                skipped_missing += 1
            continue
        total_lines += result
        files_counted += 1
        by_category[categorize_path(file_path)] += result
    return LineCount(
        total_lines=total_lines,
        files_counted=files_counted,
        skipped_binary=skipped_binary,
        skipped_missing=skipped_missing,
        by_category={category: by_category.get(category, 0) for category in FILE_CATEGORIES},
    )


def get_author_line_stats(repo: Path, author: str) -> AuthorLines:
    result = run_git(
        [
            "log",
            f"--author={author}",
            "--pretty=tformat:",
            "--numstat",
        ],
        cwd=repo,
    )
    if result.returncode != 0:
        return AuthorLines(
            added=0,
            deleted=0,
            files_changed=0,
            skipped_binary=0,
            added_by_category={category: 0 for category in FILE_CATEGORIES},
            deleted_by_category={category: 0 for category in FILE_CATEGORIES},
            files_changed_by_category={category: 0 for category in FILE_CATEGORIES},
        )
    added = 0
    deleted = 0
    files_changed = 0
    skipped_binary = 0
    added_by_category: dict[str, int] = defaultdict(int)
    deleted_by_category: dict[str, int] = defaultdict(int)
    files_changed_by_category: dict[str, int] = defaultdict(int)
    for line in result.stdout.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        add_raw, del_raw, file_path = parts[0], parts[1], parts[-1]
        if add_raw == "-" or del_raw == "-":
            skipped_binary += 1
            continue
        try:
            category = categorize_path(Path(file_path))
            added += int(add_raw)
            deleted += int(del_raw)
            files_changed += 1
            added_by_category[category] += int(add_raw)
            deleted_by_category[category] += int(del_raw)
            files_changed_by_category[category] += 1
        except ValueError:
            continue
    return AuthorLines(
        added=added,
        deleted=deleted,
        files_changed=files_changed,
        skipped_binary=skipped_binary,
        added_by_category={category: added_by_category.get(category, 0) for category in FILE_CATEGORIES},
        deleted_by_category={category: deleted_by_category.get(category, 0) for category in FILE_CATEGORIES},
        files_changed_by_category={
            category: files_changed_by_category.get(category, 0) for category in FILE_CATEGORIES
        },
    )


def format_int(value: int) -> str:
    return f"{value:,}"


def format_signed(value: int) -> Text:
    if value >= 0:
        return Text(f"+{format_int(value)}", style="green")
    return Text(f"-{format_int(abs(value))}", style="red")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Calculate meaningless git statistics.",
    )
    parser.add_argument(
        "--author",
        help="Author name/email to attribute stats to",
    )
    parser.add_argument(
        "--repo",
        help="Path inside the repo (default: cwd)",
        default=".",
    )
    args = parser.parse_args()

    repo_hint = Path(args.repo).expanduser().resolve()
    try:
        repo = get_repo_root(repo_hint)
    except RuntimeError as exc:
        err_console.print(f"[red]{exc}[/red]")
        return 1

    author = args.author or get_git_user(repo)

    repo_commits = get_commit_count(repo)
    repo_lines = count_repo_lines(repo)
    top_authors = get_top_authors(repo, limit=3)

    title = Text("Git Stats", style="bold white")
    subtitle = Text(str(repo), style="dim")
    console.print(
        Panel.fit(
            title,
            subtitle=subtitle,
            border_style="cyan",
            padding=(1, 2),
        )
    )

    repo_table = Table(
        title="Repo-wide stats",
        title_style="bold cyan",
        box=box.SIMPLE_HEAVY,
    )
    repo_table.add_column("Metric", style="bold")
    repo_table.add_column("Value", justify="right", style="cyan")
    repo_table.add_column("Notes", style="dim")
    repo_table.add_row("Commits", format_int(repo_commits), "")
    repo_table.add_row(
        "Tracked text lines",
        format_int(repo_lines.total_lines),
        f"files {format_int(repo_lines.files_counted)}",
    )
    repo_table.add_row("Code lines", format_int(repo_lines.by_category["code"]), "")
    repo_table.add_row("Docs lines", format_int(repo_lines.by_category["docs"]), ".md files")
    repo_table.add_row(
        "Config lines",
        format_int(repo_lines.by_category["config"]),
        "yaml/json/toml/conf/dotfiles",
    )
    repo_table.add_row("Other text lines", format_int(repo_lines.by_category["other"]), "")
    repo_table.add_row(
        "Binary skipped",
        format_int(repo_lines.skipped_binary),
        "tracked files with binary content",
    )
    repo_table.add_row(
        "Missing skipped",
        format_int(repo_lines.skipped_missing),
        "tracked paths missing on disk",
    )
    if top_authors:
        for idx, (name, count) in enumerate(top_authors, start=1):
            repo_table.add_row(
                f"Top author #{idx}",
                name,
                f"{format_int(count)} commits",
            )
    else:
        repo_table.add_row(
            "Top authors",
            "n/a",
            "no shortlog data",
        )
    console.print(repo_table)

    author_label = author or "unknown"
    if author:
        author_commits = get_commit_count(repo, author=author)
        author_lines = get_author_line_stats(repo, author=author)
    else:
        author_commits = 0
        author_lines = AuthorLines(
            added=0,
            deleted=0,
            files_changed=0,
            skipped_binary=0,
            added_by_category={category: 0 for category in FILE_CATEGORIES},
            deleted_by_category={category: 0 for category in FILE_CATEGORIES},
            files_changed_by_category={category: 0 for category in FILE_CATEGORIES},
        )
    net_lines = author_lines.added - author_lines.deleted

    console.print()
    author_table = Table(
        title=f"Author stats ({author_label})",
        title_style="bold green" if author else "bold yellow",
        box=box.SIMPLE_HEAVY,
    )
    author_table.add_column("Metric", style="bold")
    author_table.add_column("Value", justify="right")
    author_table.add_column("Notes", style="dim")

    if author:
        commits_value = Text(format_int(author_commits), style="green")
        added_value = Text(format_int(author_lines.added), style="green")
        deleted_value = Text(format_int(author_lines.deleted), style="red")
        net_value = format_signed(net_lines)
        files_value = Text(format_int(author_lines.files_changed), style="green")
    else:
        commits_value = Text("0", style="dim")
        added_value = Text("0", style="dim")
        deleted_value = Text("0", style="dim")
        net_value = Text("0", style="dim")
        files_value = Text("0", style="dim")

    author_table.add_row("Commits", commits_value, "")
    author_table.add_row("Lines added", added_value, "")
    author_table.add_row("Lines deleted", deleted_value, "")
    author_table.add_row("Net lines", net_value, "")
    author_table.add_row(
        "Code changes",
        Text(
            f"+{format_int(author_lines.added_by_category['code'])}/-{format_int(author_lines.deleted_by_category['code'])}"
        ),
        f"files {format_int(author_lines.files_changed_by_category['code'])}",
    )
    author_table.add_row(
        "Docs changes",
        Text(
            f"+{format_int(author_lines.added_by_category['docs'])}/-{format_int(author_lines.deleted_by_category['docs'])}"
        ),
        f".md files {format_int(author_lines.files_changed_by_category['docs'])}",
    )
    author_table.add_row(
        "Config changes",
        Text(
            f"+{format_int(author_lines.added_by_category['config'])}/-{format_int(author_lines.deleted_by_category['config'])}"
        ),
        f"files {format_int(author_lines.files_changed_by_category['config'])}",
    )
    author_table.add_row(
        "Other text changes",
        Text(
            f"+{format_int(author_lines.added_by_category['other'])}/-{format_int(author_lines.deleted_by_category['other'])}"
        ),
        f"files {format_int(author_lines.files_changed_by_category['other'])}",
    )
    author_table.add_row(
        "Files changed",
        files_value,
        f"binary skipped {format_int(author_lines.skipped_binary)}",
    )
    console.print(author_table)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
