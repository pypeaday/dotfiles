"""
Textual TUI for managing workspaces.

Provides a keyboard-driven interface to browse, add, and remove workspaces and checkouts.
"""

import pathlib


def run_tui() -> None:
    import subprocess
    from collections import Counter

    import ws
    from textual import work
    from textual.app import App
    from textual.app import ComposeResult
    from textual.binding import Binding
    from textual.containers import Grid
    from textual.containers import Horizontal
    from textual.containers import Vertical
    from textual.screen import ModalScreen
    from textual.widgets import Button
    from textual.widgets import DataTable
    from textual.widgets import Footer
    from textual.widgets import Header
    from textual.widgets import Input
    from textual.widgets import Label
    from textual.widgets import Select
    from textual.widgets import Switch
    from textual.widgets import Tree

    class ConfirmScreen(ModalScreen[bool]):
        def __init__(self, message: str, title: str = "Confirm", variant: str = "primary", confirm_text: str = "Yes"):
            super().__init__()
            self.message = message
            self.title_text = title
            self.variant = variant
            self.confirm_text = confirm_text

        def compose(self) -> ComposeResult:
            with Vertical(id="confirm-dialog"):
                yield Label(self.title_text, id="confirm-title")
                yield Label(self.message, id="confirm-message")
                with Horizontal(id="confirm-buttons"):
                    yield Button("Cancel", variant="default", id="confirm-cancel")
                    yield Button(self.confirm_text, variant=self.variant, id="confirm-yes")

        def on_button_pressed(self, event: Button.Pressed) -> None:
            if event.button.id == "confirm-yes":
                self.dismiss(True)
            else:
                self.dismiss(False)

    class NewWorkspaceScreen(ModalScreen[tuple[str, str, str]]):
        def compose(self) -> ComposeResult:
            with Grid(id="new-ws-grid"):
                yield Label("New Workspace", id="new-ws-title")
                yield Label("Area:")
                areas = [(key, key) for key in getattr(ws, "WORKSPACE_DIRS", {})]
                if areas:
                    yield Select(areas, id="ws-area", value=areas[0][0])
                else:
                    yield Select(areas, id="ws-area")
                yield Label("Name:")
                yield Input(id="ws-name")
                yield Label("Description:")
                yield Input(id="ws-desc")
                with Horizontal(id="new-ws-buttons"):
                    yield Button("Cancel", variant="default", id="ws-cancel")
                    yield Button("Create", variant="primary", id="ws-create")

        def on_button_pressed(self, event: Button.Pressed) -> None:
            if event.button.id == "ws-cancel":
                self.dismiss(None)
            elif event.button.id == "ws-create":
                area_select = self.query_one("#ws-area", Select)
                name_input = self.query_one("#ws-name", Input)
                desc_input = self.query_one("#ws-desc", Input)
                area = area_select.value if hasattr(area_select, "value") else None
                name = name_input.value if hasattr(name_input, "value") else ""
                desc = desc_input.value if hasattr(desc_input, "value") else ""

                if area and name:
                    self.dismiss((area, name, desc))
                else:
                    self.app.notify("Area and Name are required", severity="error")

    class AddCheckoutScreen(ModalScreen[dict]):
        def __init__(self, area: str, workspace: str):
            super().__init__()
            self.area = area
            self.workspace = workspace

        def compose(self) -> ComposeResult:
            with Grid(id="add-co-grid"):
                yield Label(f"Add Checkout to {self.area}/{self.workspace}", id="add-co-title")
                yield Label("Repo Path:")
                yield Input(id="co-repo")
                yield Label("Ref:")
                yield Input("HEAD", id="co-ref")
                yield Label("Mode:")
                yield Select(
                    [("detach", "detach"), ("existing", "existing"), ("new", "new")], value="detach", id="co-mode"
                )
                yield Label("New Branch (optional):")
                yield Input(id="co-new-branch")
                yield Label("Folder Name (optional):")
                yield Input(id="co-name")
                yield Label("Role:")
                yield Select(
                    [("control", "control"), ("review", "review"), ("development", "development")],
                    value="control",
                    id="co-role",
                )
                yield Label("Ephemeral:")
                yield Switch(id="co-ephemeral")
                with Horizontal(id="add-co-buttons"):
                    yield Button("Cancel", variant="default", id="co-cancel")
                    yield Button("Add", variant="primary", id="co-add")

        def on_button_pressed(self, event: Button.Pressed) -> None:
            if event.button.id == "co-cancel":
                self.dismiss(None)
            elif event.button.id == "co-add":
                repo = self.query_one("#co-repo", Input).value
                if not repo:
                    self.app.notify("Repo path is required", severity="error")
                    return
                ref = self.query_one("#co-ref", Input).value or "HEAD"
                mode = self.query_one("#co-mode", Select).value
                new_branch = self.query_one("#co-new-branch", Input).value or None
                name = self.query_one("#co-name", Input).value or None
                role = self.query_one("#co-role", Select).value or "control"
                ephemeral = self.query_one("#co-ephemeral", Switch).value
                self.dismiss(
                    {
                        "repo": pathlib.Path(repo),
                        "ref": ref,
                        "mode": mode,
                        "new_branch": new_branch,
                        "name": name,
                        "role": role,
                        "ephemeral": ephemeral,
                    }
                )

    class WsApp(App):
        CSS = """
        #main-container {
            width: 100%;
            height: 100%;
            layout: horizontal;
        }
        #left-pane {
            width: 36;
            min-width: 24;
            max-width: 44;
            height: 100%;
            border-right: solid $primary;
        }
        #right-pane {
            width: 1fr;
            height: 100%;
        }
        #workspace-tree {
            height: 1fr;
        }
        #checkout-table {
            height: 1fr;
        }
        #stats {
            height: 4;
            padding: 0 1;
            border-bottom: solid $primary;
            background: $surface;
        }
        #details {
            height: 8;
            padding: 1;
            border-top: solid $primary;
            background: $surface;
        }
        #new-ws-grid, #add-co-grid {
            grid-size: 2;
            grid-columns: 1fr 2fr;
            width: 70;
            height: auto;
            padding: 1 2;
            background: $surface;
            border: solid $primary;
        }
        #confirm-dialog {
            width: 50;
            height: auto;
            padding: 1 2;
            background: $surface;
            border: solid $primary;
            align: center middle;
        }
        #confirm-buttons {
            align: center middle;
            height: 3;
            margin-top: 1;
        }
        #new-ws-buttons, #add-co-buttons {
            column-span: 2;
            align: right middle;
            height: 3;
            margin-top: 1;
        }
        Label {
            content-align: left middle;
        }
        #new-ws-title, #add-co-title, #confirm-title {
            column-span: 2;
            text-align: center;
            text-style: bold;
            padding-bottom: 1;
        }
        #confirm-title {
            column-span: 1;
        }
        ModalScreen {
            align: center middle;
            background: $background 80%;
        }
        """

        BINDINGS = [
            Binding("q", "quit", "Quit"),
            Binding("r", "refresh", "Refresh"),
            Binding("n", "new_workspace", "New Workspace"),
            Binding("a", "add_checkout", "Add Checkout"),
            Binding("d", "delete", "Delete"),
            Binding("o", "open_tmux", "Open in Tmux"),
            Binding("enter", "open_tmux", "Open in Tmux", show=False),
            Binding("question_mark", "help", "Help", key_display="?"),
        ]

        def compose(self) -> ComposeResult:
            yield Header()
            with Horizontal(id="main-container"):
                with Vertical(id="left-pane"):
                    yield Tree("Workspaces", id="workspace-tree")
                with Vertical(id="right-pane"):
                    yield Label("", id="stats")
                    yield DataTable(id="checkout-table")
                    yield Label("Select a workspace or checkout", id="details")
            yield Footer()

        def on_mount(self) -> None:
            self.title = "Workspace Manager"
            table = self.query_one(DataTable)
            table.cursor_type = "row"
            self.workspaces = []
            self.action_refresh()

        def action_refresh(self) -> None:
            self.query_one("#stats", Label).update("[dim]Loading workspace statistics...[/dim]")
            self.load_workspaces()

        @work(thread=True, exclusive=True)
        def load_workspaces(self) -> None:
            try:
                workspaces = ws.scan_workspaces()
            except (ValueError, RuntimeError, OSError) as error:
                self.call_from_thread(self.refresh_failed, str(error))
                return
            self.call_from_thread(self.render_workspaces, workspaces)

        def refresh_failed(self, message: str) -> None:
            self.notify(f"Error scanning workspaces: {message}", severity="error")
            self.query_one("#stats", Label).update("[red]Workspace scan failed[/red]")

        def render_workspaces(self, workspaces) -> None:
            tree = self.query_one(Tree)
            tree.clear()
            self.workspaces = workspaces

            areas = {}
            for w in self.workspaces:
                if w.area not in areas:
                    areas[w.area] = tree.root.add(w.area, data={"type": "area", "name": w.area}, expand=True)
                areas[w.area].add(
                    w.name,
                    data={"type": "workspace", "workspace": w},
                    allow_expand=False,
                )

            stats = [ws.workspace_stats(workspace) for workspace in self.workspaces]
            repos = {checkout.repo.resolve() for workspace in self.workspaces for checkout in workspace.checkouts}
            roles = Counter(checkout.role for workspace in self.workspaces for checkout in workspace.checkouts)
            modes = Counter(checkout.mode for workspace in self.workspaces for checkout in workspace.checkouts)
            role_text = ", ".join(f"{name} {count}" for name, count in sorted(roles.items())) or "none"
            mode_text = ", ".join(f"{name} {count}" for name, count in sorted(modes.items())) or "none"
            self.query_one("#stats", Label).update(
                f"[bold]{len(stats)} workspaces[/bold]  "
                f"{sum(item.checkouts for item in stats)} checkouts  "
                f"{len(repos)} repos  "
                f"[red]{sum(item.dirty_checkouts for item in stats)} dirty[/red] / "
                f"{sum(item.changed_files for item in stats)} files  "
                f"[yellow]{sum(item.unpushed_commits for item in stats)} ahead[/yellow] / "
                f"{sum(item.unknown_push_state for item in stats)} unknown  "
                f"{sum(item.stale_checkouts for item in stats)} stale\n"
                f"Roles: {role_text}  |  Modes: {mode_text}"
            )
            tree.root.expand_all()
            self.update_details()

        def configure_overview_table(self, table: DataTable) -> None:
            table.clear(columns=True)
            table.add_column("Workspace", width=28)
            table.add_column("Area", width=9)
            table.add_column("Trees", width=6)
            table.add_column("Repos", width=6)
            table.add_column("Dirty", width=6)
            table.add_column("Files", width=7)
            table.add_column("Ahead", width=7)
            table.add_column("Unknown", width=8)
            table.add_column("Stale", width=6)
            table.add_column("Activity", width=9)

        def configure_checkout_table(self, table: DataTable) -> None:
            table.clear(columns=True)
            table.add_column("Checkout", width=30)
            table.add_column("Repo", width=18)
            table.add_column("Role", width=12)
            table.add_column("Mode", width=8)
            table.add_column("Files", width=6)
            table.add_column("Ahead", width=7)
            table.add_column("Age", width=7)
            table.add_column("State", width=9)

        def show_overview(self, area: str | None = None) -> None:
            table = self.query_one(DataTable)
            details = self.query_one("#details", Label)
            self.configure_overview_table(table)
            visible = [workspace for workspace in self.workspaces if area is None or workspace.area == area]
            for workspace in visible:
                stats = ws.workspace_stats(workspace)
                activity = (
                    "unknown" if stats.age_days < 0 else ("today" if stats.age_days == 0 else f"{stats.age_days}d")
                )
                table.add_row(
                    workspace.name,
                    workspace.area,
                    str(stats.checkouts),
                    str(stats.repositories),
                    str(stats.dirty_checkouts),
                    str(stats.changed_files),
                    str(stats.unpushed_commits),
                    str(stats.unknown_push_state),
                    str(stats.stale_checkouts),
                    activity,
                )
            scope = f"{area} workspaces" if area else "all workspaces"
            details.update(
                f"Dashboard: {scope}\n"
                "Select a workspace for checkout metrics. "
                "Press r to refresh or o to open the selected scope."
            )

        def update_details(self) -> None:
            tree = self.query_one(Tree)
            table = self.query_one(DataTable)
            details = self.query_one("#details", Label)

            node = tree.cursor_node
            if not node or not node.data:
                self.show_overview()
                return
            if node.data.get("type") == "area":
                self.show_overview(node.data["name"])
                return

            w = node.data.get("workspace")
            if not w:
                return

            stats = ws.workspace_stats(w)
            roles = ", ".join(f"{name} {count}" for name, count in stats.roles) or "none"
            modes = ", ".join(f"{name} {count}" for name, count in stats.modes) or "none"
            activity = (
                "unknown" if stats.age_days < 0 else ("today" if stats.age_days == 0 else f"{stats.age_days}d ago")
            )
            details.update(
                f"Workspace: {w.area}/{w.name} - {w.description}\n"
                f"{stats.checkouts} checkouts / {stats.repositories} repos | "
                f"{stats.dirty_checkouts} dirty / {stats.changed_files} files | "
                f"{stats.unpushed_commits} ahead / {stats.unknown_push_state} unknown | "
                f"activity {activity}\n"
                f"Roles: {roles} | Modes: {modes}\n"
                f"Path: {w.path}"
            )

            self.configure_checkout_table(table)
            for i, co in enumerate(w.checkouts):
                state = "dirty" if co.dirty else "clean"
                unpushed_str = "?" if co.unpushed < 0 else str(co.unpushed)
                age = "?" if co.age_days < 0 else f"{co.age_days}d"
                table.add_row(
                    co.name,
                    co.repo.name,
                    co.role,
                    co.mode,
                    str(co.changed_files),
                    unpushed_str,
                    age,
                    state,
                    key=str(i),
                )

        def on_tree_node_highlighted(self, event: Tree.NodeHighlighted) -> None:
            self.update_details()

        def on_data_table_row_highlighted(self, event: DataTable.RowHighlighted) -> None:
            tree = self.query_one(Tree)
            node = tree.cursor_node
            if node and node.data and node.data.get("type") == "workspace":
                w = node.data["workspace"]
                try:
                    idx = int(event.row_key.value)
                except ValueError:
                    return
                if idx < len(w.checkouts):
                    co = w.checkouts[idx]
                    details = self.query_one("#details", Label)
                    details.update(
                        f"Checkout: {co.name} ({co.role})\n"
                        f"Path: {co.path}\n"
                        f"Repo: {co.repo}\n"
                        f"Mode: {co.mode} Ref: {co.ref}\n"
                        f"Changed files: {co.changed_files} | "
                        f"Ahead: {'unknown' if co.unpushed < 0 else co.unpushed} | "
                        f"Age: {'unknown' if co.age_days < 0 else f'{co.age_days}d'}"
                    )

        def get_selected_item(self):
            if self.query_one(DataTable).has_focus:
                tree = self.query_one(Tree)
                node = tree.cursor_node
                if node and node.data and node.data.get("type") == "workspace":
                    w = node.data["workspace"]
                    table = self.query_one(DataTable)
                    if table.row_count > 0 and table.cursor_row is not None:
                        row_key = table.coordinate_to_cell_key(table.cursor_coordinate).row_key
                        try:
                            idx = int(row_key.value)
                            if idx < len(w.checkouts):
                                return "checkout", w.checkouts[idx]
                        except ValueError:
                            pass
            else:
                tree = self.query_one(Tree)
                node = tree.cursor_node
                if node and node.data and node.data.get("type") == "workspace":
                    return "workspace", node.data["workspace"]
            return None, None

        def action_new_workspace(self) -> None:
            def check_new_ws(result):
                if result:
                    area, name, desc = result
                    try:
                        ws.create_workspace_record(area, name, desc)
                        self.notify(f"Created workspace {area}/{name}")
                        self.action_refresh()
                    except (ValueError, RuntimeError, OSError) as e:
                        self.notify(f"Error: {e}", severity="error")

            self.push_screen(NewWorkspaceScreen(), check_new_ws)

        def action_add_checkout(self) -> None:
            tree = self.query_one(Tree)
            node = tree.cursor_node
            if not node or not node.data or node.data.get("type") != "workspace":
                self.notify("Select a workspace first in the tree", severity="warning")
                return

            w = node.data["workspace"]

            def check_add_co(result):
                if result:
                    try:
                        ws.add_checkout(
                            area=w.area,
                            workspace=w.name,
                            repo=result["repo"],
                            ref=result["ref"],
                            mode=result["mode"],
                            new_branch=result["new_branch"],
                            name=result["name"],
                            role=result["role"],
                            ephemeral=result["ephemeral"],
                        )
                        self.notify("Checkout added successfully")
                        self.action_refresh()
                    except (ValueError, RuntimeError, OSError) as e:
                        self.notify(f"Error adding checkout: {e}", severity="error")

            self.push_screen(AddCheckoutScreen(w.area, w.name), check_add_co)

        def action_delete(self) -> None:
            itype, item = self.get_selected_item()
            if not itype:
                self.notify("Nothing selected to delete (focus a workspace or checkout)", severity="warning")
                return

            if itype == "checkout":
                co = item

                def confirm_first(confirmed: bool):
                    if confirmed:
                        try:
                            ws.remove_checkout(co.path, force=False)
                            self.notify(f"Removed checkout {co.name}")
                            self.action_refresh()
                        except RuntimeError as e:

                            def confirm_force(force: bool):
                                if force:
                                    try:
                                        ws.remove_checkout(co.path, force=True)
                                        self.notify(f"Force removed checkout {co.name}")
                                        self.action_refresh()
                                    except (ValueError, RuntimeError, OSError) as ex:
                                        self.notify(f"Error force removing checkout: {ex}", severity="error")

                            self.push_screen(
                                ConfirmScreen(
                                    f"Failed to remove: {e}\nForce remove?",
                                    title="Force Remove Checkout",
                                    variant="error",
                                    confirm_text="Yes, Force",
                                ),
                                confirm_force,
                            )
                        except (ValueError, OSError) as e:
                            self.notify(f"Error removing checkout: {e}", severity="error")

                self.push_screen(
                    ConfirmScreen(
                        f"Remove checkout {co.name}?", title="Remove Checkout", variant="error", confirm_text="Remove"
                    ),
                    confirm_first,
                )

            elif itype == "workspace":
                w = item

                def confirm_first_ws(confirmed: bool):
                    if confirmed:
                        try:
                            ws.remove_workspace_record(w.area, w.name, force=False)
                            self.notify(f"Removed workspace {w.area}/{w.name}")
                            self.action_refresh()
                        except RuntimeError as e:

                            def confirm_force_ws(force: bool):
                                if force:
                                    try:
                                        ws.remove_workspace_record(w.area, w.name, force=True)
                                        self.notify(f"Force removed workspace {w.area}/{w.name}")
                                        self.action_refresh()
                                    except (ValueError, RuntimeError, OSError) as ex:
                                        self.notify(f"Error force removing workspace: {ex}", severity="error")

                            self.push_screen(
                                ConfirmScreen(
                                    f"Failed to remove: {e}\nForce remove?",
                                    title="Force Remove Workspace",
                                    variant="error",
                                    confirm_text="Yes, Force",
                                ),
                                confirm_force_ws,
                            )
                        except (ValueError, OSError) as e:
                            self.notify(f"Error removing workspace: {e}", severity="error")

                self.push_screen(
                    ConfirmScreen(
                        f"Remove workspace {w.area}/{w.name}?",
                        title="Remove Workspace",
                        variant="error",
                        confirm_text="Remove",
                    ),
                    confirm_first_ws,
                )

        def action_open_tmux(self) -> None:
            itype, item = self.get_selected_item()
            if not itype:
                self.notify("Nothing selected to open (focus a workspace or checkout)", severity="warning")
                return

            if itype == "checkout":
                path = item.path
                session_name = ws.tmux_session_name(item.area, item.workspace)
            else:
                path = item.path
                session_name = ws.tmux_session_name(item.area, item.name)

            try:
                with self.suspend():
                    ws.open_in_tmux(path, session_name)
            except (ValueError, RuntimeError, OSError, subprocess.CalledProcessError) as e:
                self.notify(f"Error opening tmux: {e}", severity="error")

        def action_help(self) -> None:
            help_msg = (
                "Workspaces Manager\n\n"
                "q: Quit\n"
                "r: Refresh\n"
                "n: New Workspace\n"
                "a: Add Checkout to selected workspace\n"
                "d: Delete selected workspace or checkout\n"
                "o/Enter: Open selected in Tmux\n"
                "?: This help\n\n"
                "Use Tab/Shift+Tab to switch focus between the tree and the table.\n"
            )
            self.app.notify(help_msg, title="Help", timeout=5)

    app = WsApp()
    app.run()
