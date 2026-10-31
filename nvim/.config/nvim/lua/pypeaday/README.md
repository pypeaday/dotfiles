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

## Bible

ESV passage lookup, same experience as the sermon-prep app's `[[ref` autocomplete.

### Commands

- `:Bible <ref>`: fetches the passage from api.esv.org and inserts it below the cursor as a journal-style scripture admonition — collapsible `??? scripture "<canonical ref>"` by default, expanded `!!! scripture` with `:Bible! <ref>` (matches the notes' readings vs memory-verse pattern). Verses land one-per-line as `N. text`, with the Crossway copyright notice as a final italic line inside the block. Accepts aliases (`:Bible 2cor4:16`, `:Bible ii corinthians 4:16-18`, `:Bible jn 3:16`), verse ranges, whole chapters (`:Bible Psa 23`), and chapter ranges (`:Bible John 3-4`). `;`-separated multi-passage refs are not supported.
- `:Bible` (bare): guided picker — `vim.ui.select` book -> chapter -> start verse -> optional end verse -> insert. Cancelling any step aborts quietly.
- Tab-completion is stage-aware: book names/aliases, then chapters for the picked book, then verses for `ch:`, then range ends for `ch:v-`. Chapter/verse counts come from `bible/chapters.lua` (generated from sermon-prep's `public/bible/bsb/index.json`).

### Keymaps

- `<leader>bi`: the guided picker (same as bare `:Bible`).

### How it Works

Fetches are async (`vim.system` + `curl`); results cache for the session. The API key comes from `$ESV_API_KEY` or `~/dotfiles/private/.esv.key` (gitignored; `set_esv` alias in zshrc exports it). Parsing normalizes book aliases to a canonical name then hands the numeric tail to the ESV API, so anything the API can't parse just errors via `vim.notify`.
