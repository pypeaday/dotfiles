# Pypeaday's Plugins

## Daily

This plugin provides a set of functions and keymaps to help manage a Zettelkasten-style daily notes system.

### Features

- **Daily Note Management**: Quickly open or create a new daily note for the current day.
- **File Finder**: Easily search for files within your daily notes directory.
- **Backlinks**: Find all the notes that link to the current note.

### Commands

- `:DailyNote` or `:Daily`: Opens today's daily note. If it doesn't exist, it will be created.
- `:BackLinks`: Shows a list of all notes that have a wikilink to the current note.

### Keymaps

- `<leader>dn`: Opens or creates the daily note for the current day.
- `<leader>df`: Opens a Telescope finder to search for files in the `pages/daily` directory.
- `<leader>dl`: Opens a Telescope finder to show all backlinks for the current file.

### How it Works

The plugin is designed to work with a directory structure where daily notes are stored in `pages/daily`. The `check_and_open_daily_note` function uses a `copier` template to create new daily notes, ensuring a consistent format. The `find_backlinks` and `find_daily_files` functions use `telescope.nvim` to provide an interactive menu for searching and navigating your notes.
