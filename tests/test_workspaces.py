from __future__ import annotations

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import call
from unittest.mock import patch

from typer.testing import CliRunner

SCRIPT = Path(__file__).parents[1] / "workspaces/.local/bin/ws.py"
SPEC = importlib.util.spec_from_file_location("ws", SCRIPT)
assert SPEC and SPEC.loader
ws = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ws)


def run_git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


class WorkspaceLifecycleTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.repo = self.root / "repo"
        self.remote = self.root / "remote.git"
        self.personal = self.root / "personal.workspaces"
        self.work = self.root / "work.workspaces"

        subprocess.run(["git", "init", "--bare", str(self.remote)], check=True, capture_output=True)
        subprocess.run(
            ["git", "init", "-b", "main", str(self.repo)],
            check=True,
            capture_output=True,
        )
        run_git(self.repo, "config", "user.name", "Test User")
        run_git(self.repo, "config", "user.email", "test@example.com")
        (self.repo / "README.md").write_text("test\n")
        run_git(self.repo, "add", "README.md")
        run_git(self.repo, "commit", "-m", "initial")
        run_git(self.repo, "remote", "add", "origin", str(self.remote))
        run_git(self.repo, "push", "-u", "origin", "main")
        self.dirs = {"personal": self.personal, "work": self.work}
        self.patch = patch.object(ws, "WORKSPACE_DIRS", self.dirs)
        self.patch.start()
        self.kill_windows_patch = patch.object(ws, "kill_tmux_windows_for_path")
        self.kill_sessions_patch = patch.object(ws, "kill_tmux_sessions")
        self.kill_windows_patch.start()
        self.kill_sessions_patch.start()

    def tearDown(self) -> None:
        self.kill_sessions_patch.stop()
        self.kill_windows_patch.stop()
        self.patch.stop()
        self.temporary.cleanup()

    def test_checkout_modes_and_metadata(self) -> None:
        workspace = ws.create_workspace_record("work", "review-batch", "Review queued PRs")
        detached = ws.add_checkout(
            "work",
            "review-batch",
            self.repo,
            mode="detach",
            ref="origin/main",
            name="control",
            role="control",
            ephemeral=True,
        )
        run_git(self.repo, "branch", "review")
        existing = ws.add_checkout(
            "work",
            "review-batch",
            self.repo,
            mode="existing",
            ref="review",
            name="pr-review",
            role="review",
        )
        created = ws.add_checkout(
            "work",
            "review-batch",
            self.repo,
            mode="new",
            ref="origin/main",
            new_branch="debug/infra",
            name="infra-debug",
            role="development",
        )

        summary = ws.scan_workspaces()[0]
        self.assertEqual(summary.path, workspace)
        self.assertEqual(summary.description, "Review queued PRs")
        self.assertEqual(
            {checkout.name for checkout in summary.checkouts},
            {"control", "pr-review", "infra-debug"},
        )
        self.assertTrue(next(item for item in summary.checkouts if item.path == detached).ephemeral)
        self.assertEqual(next(item for item in summary.checkouts if item.path == existing).branch, "review")
        self.assertEqual(
            next(item for item in summary.checkouts if item.path == created).branch,
            "debug/infra",
        )

        ws.remove_workspace_record("work", "review-batch")
        self.assertFalse(workspace.exists())

    def test_cleanup_refuses_dirty_and_unpushed_checkouts(self) -> None:
        ws.create_workspace_record("personal", "safe-cleanup")
        detached = ws.add_checkout(
            "personal",
            "safe-cleanup",
            self.repo,
            mode="detach",
            name="dirty",
        )
        (detached / "dirty.txt").write_text("dirty\n")
        with self.assertRaisesRegex(RuntimeError, "uncommitted changes"):
            ws.remove_checkout(detached)
        run_git(detached, "add", "dirty.txt")
        run_git(detached, "commit", "-m", "detached local work")
        with self.assertRaisesRegex(RuntimeError, "unpushed commit"):
            ws.remove_checkout(detached)
        ws.remove_checkout(detached, force=True)

        branch = ws.add_checkout(
            "personal",
            "safe-cleanup",
            self.repo,
            mode="new",
            new_branch="local-work",
            name="unpushed",
        )
        (branch / "work.txt").write_text("work\n")
        run_git(branch, "add", "work.txt")
        run_git(branch, "commit", "-m", "local work")
        with self.assertRaisesRegex(RuntimeError, "unpushed commit"):
            ws.remove_checkout(branch)
        ws.remove_checkout(branch, force=True)

    def test_cli_detached_checkout_defaults_to_control_name(self) -> None:
        ws.create_workspace_record("work", "detached-default")
        ws._add_worktree(
            area="work",
            workspace="detached-default",
            repo=str(self.repo),
            branch=None,
            custom_name=None,
            detach=True,
        )

        checkout = ws.scan_workspaces()[0].checkouts[0]
        self.assertEqual(checkout.name, "repo-control")
        self.assertEqual(checkout.role, "control")
        self.assertEqual(checkout.mode, "detach")

    def test_interactive_detached_checkout_prompts_for_name(self) -> None:
        ws.create_workspace_record("work", "named-detached")
        with (
            patch.object(
                ws,
                "pick_checkout_spec",
                return_value=("detach", "HEAD", None),
            ),
            patch.object(
                ws.Prompt,
                "ask",
                side_effect=["review", "pr-review-control"],
            ),
        ):
            ws._add_worktree(
                area="work",
                workspace="named-detached",
                repo=str(self.repo),
                branch=None,
                custom_name=None,
            )

        checkout = ws.scan_workspaces()[0].checkouts[0]
        self.assertEqual(checkout.name, "pr-review-control")
        self.assertEqual(checkout.role, "review")
        self.assertEqual(checkout.mode, "detach")

    def test_unknown_push_state_blocks_safe_removal(self) -> None:
        local_repo = self.root / "local-only"
        subprocess.run(
            ["git", "init", "-b", "main", str(local_repo)],
            check=True,
            capture_output=True,
        )
        run_git(local_repo, "config", "user.name", "Test User")
        run_git(local_repo, "config", "user.email", "test@example.com")
        (local_repo / "README.md").write_text("local\n")
        run_git(local_repo, "add", "README.md")
        run_git(local_repo, "commit", "-m", "initial")
        run_git(local_repo, "branch", "local-work")
        ws.create_workspace_record("personal", "local-only")
        checkout = ws.add_checkout(
            "personal",
            "local-only",
            local_repo,
            mode="existing",
            ref="local-work",
        )

        self.assertEqual(ws.get_unpushed_count(checkout), -1)
        with self.assertRaisesRegex(RuntimeError, "Cannot verify"):
            ws.remove_checkout(checkout)
        ws.remove_checkout(checkout, force=True)

    def test_failed_new_checkout_removes_created_branch(self) -> None:
        ws.create_workspace_record("work", "rollback")
        original_save = ws._save_metadata

        def fail_checkout_metadata(path, metadata):
            if metadata["checkouts"]:
                raise OSError("metadata write failed")
            original_save(path, metadata)

        with (
            patch.object(ws, "_save_metadata", side_effect=fail_checkout_metadata),
            self.assertRaisesRegex(OSError, "metadata write failed"),
        ):
            ws.add_checkout(
                "work",
                "rollback",
                self.repo,
                mode="new",
                new_branch="temporary-branch",
            )

        branches = run_git(self.repo, "branch", "--format=%(refname:short)").splitlines()
        self.assertNotIn("temporary-branch", branches)
        self.assertFalse((self.work / "rollback/repo-temporary-branch").exists())

    def test_workspace_paths_get_unique_tmux_session_names(self) -> None:
        workspace = ws.create_workspace_record("work", "review-batch")
        checkout = ws.add_checkout(
            "work",
            "review-batch",
            self.repo,
            mode="detach",
            name="control",
        )

        self.assertEqual(
            ws.tmux_session_name_for_path(workspace),
            ws.tmux_session_name("work", "review-batch"),
        )
        self.assertEqual(
            ws.tmux_session_name_for_path(checkout),
            ws.tmux_session_name("work", "review-batch"),
        )

    def test_tmux_session_names_do_not_collapse_punctuation(self) -> None:
        dotted = ws.tmux_session_name("work", "foo.bar")
        underscored = ws.tmux_session_name("work", "foo_bar")

        self.assertNotEqual(dotted, underscored)
        self.assertEqual(dotted, "work_foo_2e_bar")
        self.assertEqual(underscored, "work_foo_5f_bar")

    def test_checkout_opens_as_window_in_workspace_session(self) -> None:
        workspace = ws.create_workspace_record("work", "review-batch")
        checkout = ws.add_checkout(
            "work",
            "review-batch",
            self.repo,
            mode="detach",
            name="control",
        )
        completed = subprocess.CompletedProcess([], 0, "", "")

        with (
            patch.object(ws, "_checkout_window", return_value="@9") as checkout_window,
            patch.object(ws.subprocess, "run", return_value=completed) as run,
            patch.dict(ws.os.environ, {}, clear=True),
        ):
            ws.open_in_tmux(checkout, "ignored")

        session_name = ws.tmux_session_name("work", "review-batch")
        checkout_window.assert_called_once_with(session_name, checkout)
        self.assertIn(
            call(
                ["tmux", "attach-session", "-t", session_name],
                check=True,
            ),
            run.call_args_list,
        )
        self.assertEqual(ws.tmux_session_name_for_path(workspace), session_name)

    def test_checkout_window_is_reused_after_changing_directory(self) -> None:
        checkout = self.root / "workspace/control"
        checkout.mkdir(parents=True)
        listed = subprocess.CompletedProcess(
            [],
            0,
            f"@7\t{checkout}\t{checkout}/src\n",
            "",
        )

        with patch.object(ws.subprocess, "run", return_value=listed) as run:
            window_id = ws._checkout_window("work_review-batch", checkout)

        self.assertEqual(window_id, "@7")
        self.assertEqual(run.call_count, 1)

    def test_remove_command_rejects_checkout_path_traversal(self) -> None:
        ws.create_workspace_record("work", "safe-scope")
        checkout = ws.add_checkout(
            "work",
            "safe-scope",
            self.repo,
            mode="detach",
            name="control",
        )

        result = CliRunner().invoke(
            ws.app,
            [
                "worktree",
                "remove",
                "work",
                "safe-scope",
                "../control",
                "--force",
            ],
        )

        self.assertEqual(result.exit_code, 2)
        self.assertIn("single non-empty path component", result.output)
        self.assertTrue(checkout.exists())

    def test_stats_report_and_json_cli(self) -> None:
        ws.create_workspace_record("work", "stats")
        checkout = ws.add_checkout(
            "work",
            "stats",
            self.repo,
            mode="detach",
            name="control",
            role="control",
        )
        (checkout / "changed.txt").write_text("changed\n")

        report = ws.stats_report()
        row = report["workspaces"][0]
        self.assertEqual(report["totals"]["workspaces"], 1)
        self.assertEqual(report["totals"]["checkouts"], 1)
        self.assertEqual(report["totals"]["roles"], {"control": 1})
        self.assertEqual(report["totals"]["modes"], {"detach": 1})
        self.assertEqual(row["dirty_checkouts"], 1)
        self.assertEqual(row["changed_files"], 1)
        self.assertGreaterEqual(row["age_days"], 0)

        result = CliRunner().invoke(ws.app, ["stats", "--json"])
        self.assertEqual(result.exit_code, 0)
        self.assertEqual(json.loads(result.output)["totals"]["changed_files"], 1)


if __name__ == "__main__":
    unittest.main()
