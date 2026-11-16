---@diagnostic disable: undefined-global
-- vim is a global in Neovim Lua scripts

-- Bible passage lookup via the ESV API (https://api.esv.org/v3/passage/text/).
-- Ported from ~/projects/personal/sermon-prep (src/bible.js + server/index.js):
-- same alias handling ("2cor4:16", "ii corinthians", "jn", ...) and the same
-- query shape ("<Book Name> <ch>:<v1>-<v2>").
--
-- API key resolution (never committed — private/ is gitignored):
--   1. $ESV_API_KEY env var  (zsh: `set_esv` alias)
--   2. ~/dotfiles/private/.esv.key  (raw key file, same convention as .openai.key)

local M = {}

local CHAPTERS = require("pypeaday.bible.chapters")

local KEY_FILE = vim.fn.expand("~/dotfiles/private/.esv.key")

-- Required by Crossway's API terms; appended once per inserted quote.
local COPYRIGHT =
  "Scripture quotations are from the ESV® Bible (The Holy Bible, English Standard Version®), copyright © 2001 by Crossway, a publishing ministry of Good News Publishers. Used by permission. All rights reserved."

-- Book ids follow the sermon-prep vendored index (BSB usfm-ish codes).
-- `abbr` is a common short form; `aliases` mirrors EXTRA_ALIASES in bible.js.
local BOOKS = {
  { id = "GEN", name = "Genesis", abbr = "gen", aliases = { "gen" } },
  { id = "EXO", name = "Exodus", abbr = "exod", aliases = { "exod", "ex" } },
  { id = "LEV", name = "Leviticus", abbr = "lev", aliases = { "lev" } },
  { id = "NUM", name = "Numbers", abbr = "num", aliases = { "num" } },
  { id = "DEU", name = "Deuteronomy", abbr = "deut", aliases = { "deut", "dt" } },
  { id = "JOS", name = "Joshua", abbr = "josh", aliases = { "josh" } },
  { id = "JDG", name = "Judges", abbr = "judg", aliases = { "judg", "judges" } },
  { id = "RUT", name = "Ruth", abbr = "ruth", aliases = { "ruth" } },
  { id = "1SA", name = "1 Samuel", abbr = "1sam", aliases = { "1sam", "sam", "samuel" } },
  { id = "2SA", name = "2 Samuel", abbr = "2sam", aliases = { "2sam", "sam", "samuel" } },
  { id = "1KI", name = "1 Kings", abbr = "1kgs", aliases = { "1kgs", "kgs", "kings" } },
  { id = "2KI", name = "2 Kings", abbr = "2kgs", aliases = { "2kgs", "kgs", "kings" } },
  { id = "1CH", name = "1 Chronicles", abbr = "1chr", aliases = { "1chr", "chr", "chronicles" } },
  { id = "2CH", name = "2 Chronicles", abbr = "2chr", aliases = { "2chr", "chr", "chronicles" } },
  { id = "EZR", name = "Ezra", abbr = "ezra", aliases = { "ezra" } },
  { id = "NEH", name = "Nehemiah", abbr = "neh", aliases = { "neh" } },
  { id = "EST", name = "Esther", abbr = "esth", aliases = { "esth", "esther" } },
  { id = "JOB", name = "Job", abbr = "job", aliases = { "job" } },
  { id = "PSA", name = "Psalm", abbr = "ps", aliases = { "ps", "psalm", "psalms", "pss" } },
  { id = "PRO", name = "Proverbs", abbr = "prov", aliases = { "prov", "proverbs" } },
  { id = "ECC", name = "Ecclesiastes", abbr = "eccl", aliases = { "eccl", "ecclesiastes", "qoheleth" } },
  { id = "SNG", name = "Song of Solomon", abbr = "song", aliases = { "song of solomon", "sos", "song", "canticles" } },
  { id = "ISA", name = "Isaiah", abbr = "isa", aliases = { "isa", "isaiah" } },
  { id = "JER", name = "Jeremiah", abbr = "jer", aliases = { "jer", "jeremiah" } },
  { id = "LAM", name = "Lamentations", abbr = "lam", aliases = { "lam", "lamentations" } },
  { id = "EZK", name = "Ezekiel", abbr = "ezek", aliases = { "ezek", "ezekiel", "eze" } },
  { id = "DAN", name = "Daniel", abbr = "dan", aliases = { "dan", "daniel" } },
  { id = "HOS", name = "Hosea", abbr = "hos", aliases = { "hos", "hosea" } },
  { id = "JOL", name = "Joel", abbr = "joel", aliases = { "joel" } },
  { id = "AMO", name = "Amos", abbr = "amos", aliases = { "amos" } },
  { id = "OBA", name = "Obadiah", abbr = "obad", aliases = { "obad" } },
  { id = "JON", name = "Jonah", abbr = "jonah", aliases = { "jonah" } },
  { id = "MIC", name = "Micah", abbr = "mic", aliases = { "mic" } },
  { id = "NAM", name = "Nahum", abbr = "nah", aliases = { "nah" } },
  { id = "HAB", name = "Habakkuk", abbr = "hab", aliases = { "hab" } },
  { id = "ZEP", name = "Zephaniah", abbr = "zeph", aliases = { "zeph", "zephaniah" } },
  { id = "HAG", name = "Haggai", abbr = "hag", aliases = { "hag" } },
  { id = "ZEC", name = "Zechariah", abbr = "zech", aliases = { "zech", "zechariah" } },
  { id = "MAL", name = "Malachi", abbr = "mal", aliases = { "mal" } },
  { id = "MAT", name = "Matthew", abbr = "matt", aliases = { "matt", "mt" } },
  { id = "MRK", name = "Mark", abbr = "mark", aliases = { "mk" } },
  { id = "LUK", name = "Luke", abbr = "luke", aliases = { "lk" } },
  { id = "JHN", name = "John", abbr = "john", aliases = { "jn", "john" } },
  { id = "ACT", name = "Acts", abbr = "acts", aliases = { "acts" } },
  { id = "ROM", name = "Romans", abbr = "rom", aliases = { "rom", "romans" } },
  { id = "1CO", name = "1 Corinthians", abbr = "1cor", aliases = { "1cor", "cor", "corinthians" } },
  { id = "2CO", name = "2 Corinthians", abbr = "2cor", aliases = { "2cor", "cor", "corinthians" } },
  { id = "GAL", name = "Galatians", abbr = "gal", aliases = { "gal" } },
  { id = "EPH", name = "Ephesians", abbr = "eph", aliases = { "eph" } },
  { id = "PHP", name = "Philippians", abbr = "phil", aliases = { "phil", "philippians" } },
  { id = "COL", name = "Colossians", abbr = "col", aliases = { "col" } },
  { id = "1TH", name = "1 Thessalonians", abbr = "1thess", aliases = { "1thess", "thess", "thessalonians" } },
  { id = "2TH", name = "2 Thessalonians", abbr = "2thess", aliases = { "2thess", "thess", "thessalonians" } },
  { id = "1TI", name = "1 Timothy", abbr = "1tim", aliases = { "1tim", "tim", "timothy" } },
  { id = "2TI", name = "2 Timothy", abbr = "2tim", aliases = { "2tim", "tim", "timothy" } },
  { id = "TIT", name = "Titus", abbr = "tit", aliases = { "titus" } },
  { id = "PHM", name = "Philemon", abbr = "phlm", aliases = { "philemon", "phlm" } },
  { id = "HEB", name = "Hebrews", abbr = "heb", aliases = { "heb", "hebrews" } },
  { id = "JAS", name = "James", abbr = "jas", aliases = { "james" } },
  { id = "1PE", name = "1 Peter", abbr = "1pet", aliases = { "1pet", "pet", "peter" } },
  { id = "2PE", name = "2 Peter", abbr = "2pet", aliases = { "2pet", "pet", "peter" } },
  { id = "1JN", name = "1 John", abbr = "1jn", aliases = { "1jn", "1john" } },
  { id = "2JN", name = "2 John", abbr = "2jn", aliases = { "2jn", "2john" } },
  { id = "3JN", name = "3 John", abbr = "3jn", aliases = { "3jn", "3john" } },
  { id = "JUD", name = "Jude", abbr = "jud", aliases = { "jude" } },
  { id = "REV", name = "Revelation", abbr = "rev", aliases = { "revelation", "rev", "apocalypse" } },
}

local NUM_WORDS = {
  ["1"] = { "1", "i", "first", "1st" },
  ["2"] = { "2", "ii", "second", "2nd" },
  ["3"] = { "3", "iii", "third", "3rd" },
}

local alias_map -- alias (normalized) -> list of book entries
local function build_aliases()
  if alias_map then
    return alias_map
  end
  alias_map = {}
  local function add(alias, book)
    alias = alias:lower():gsub("%.", "")
    alias_map[alias] = alias_map[alias] or {}
    for _, b in ipairs(alias_map[alias]) do
      if b.id == book.id then
        return
      end
    end
    table.insert(alias_map[alias], book)
  end
  for _, b in ipairs(BOOKS) do
    local n, rest = b.name:match("^(%d)%s+(.+)$")
    if n then
      -- tails: every name/alias for the book with its leading digit stripped,
      -- e.g. 2CO -> {"corinthians", "cor"}; then cross with number-words so
      -- "2 cor", "ii corinthians", "2nd cor", "second corinthians" all work.
      local tails = { [rest:lower()] = true }
      for _, a in ipairs(b.aliases) do
        local t = a:gsub("^%d+%s*", "")
        if t ~= "" then
          tails[t] = true
        end
      end
      tails[b.abbr:gsub("^%d+%s*", "")] = true
      for tail in pairs(tails) do
        add(tail, b) -- bare tail ("corinthians") maps to both books; first wins
        for _, num in ipairs(NUM_WORDS[n]) do
          add(num .. " " .. tail, b)
          add(num .. tail, b)
        end
      end
    else
      add(b.name, b)
    end
    add(b.abbr, b)
    add(b.id, b)
    for _, a in ipairs(b.aliases) do
      add(a, b)
    end
  end
  return alias_map
end

local function norm(s)
  return (s:lower():gsub("%.", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Split input into (bookText, refText): longest leading span that is an exact alias.
local function split_ref(input, al)
  local words = {}
  for w in input:gmatch("%S+") do
    table.insert(words, w)
  end
  for i = math.min(#words, 4), 1, -1 do
    local cand = norm(table.concat(words, " ", 1, i))
    if al[cand] then
      return cand, table.concat(words, " ", i + 1)
    end
  end
  -- single squashed token like "2cor4:16" — try leading alpha part
  local head, tail = input:match("^([1-3]?[a-z]+)%s*(.-)%s*$")
  if head and al[norm(head)] then
    return norm(head), tail
  end
  return nil, input
end

--- Parse a reference like "2 Cor 4:16" or "2cor4:16-18".
--- Returns { query = "2 Corinthians 4:16-18" } or nil, errmsg.
--- The numeric tail is passed through to the ESV API mostly verbatim — it
--- handles "23" (chapter), "4:16", "4:16-18", "3-4" (chapter range), and even
--- "3:16-4:1" (cross-chapter). Not supported: ;-separated multi-passages.
function M.parse(input)
  local al = build_aliases()
  local book_key, rest = split_ref(norm(input), al)
  if not book_key then
    return nil, "unrecognized book in: " .. input
  end
  rest = norm(rest)
  if rest == "" then
    return nil, "missing chapter/verse after: " .. book_key
  end
  if not rest:match("^[%d:%,%-]+$") then
    return nil, "unparseable chapter/verse: " .. rest
  end
  local book = al[book_key][1]
  return { query = book.name .. " " .. rest, book = book.name, tail = rest }
end

-- ---------------------------------------------------------------------------
-- API key + fetch
-- ---------------------------------------------------------------------------

local cached_key -- false = "looked, not found"
function M.api_key()
  if cached_key ~= nil then
    return cached_key or nil
  end
  local k = vim.env.ESV_API_KEY
  if k and k ~= "" then
    cached_key = k
    return k
  end
  if vim.fn.filereadable(KEY_FILE) == 1 then
    k = vim.trim(vim.fn.readfile(KEY_FILE)[1] or "")
    if k ~= "" then
      cached_key = k
      return k
    end
  end
  cached_key = false
  return nil
end

-- curl via a stdin config so the token never shows in argv/ps.
local function fetch(query, cb)
  local key = M.api_key()
  if not key then
    cb(nil, "no ESV API key (set $ESV_API_KEY or write " .. KEY_FILE .. ")")
    return
  end
  -- token travels via a stdin config file so it never shows in argv/ps
  local cfg = 'header = "Authorization: Token ' .. key .. '"\n'
  vim.system({
    "curl",
    "-sSf",
    "-G",
    "--config",
    "-",
    "https://api.esv.org/v3/passage/text/",
    "--data-urlencode",
    "q=" .. query,
    "--data-urlencode",
    "include-verse-numbers=true",
    "--data-urlencode",
    "include-first-verse-numbers=true",
    "--data-urlencode",
    "include-chapter-numbers=false",
    "--data-urlencode",
    "include-headings=false",
    "--data-urlencode",
    "include-footnotes=false",
    "--data-urlencode",
    "include-footnote-body=false",
    "--data-urlencode",
    "include-short-copyright=false",
    "--data-urlencode",
    "include-copyright=false",
    "--data-urlencode",
    "include-passage-references=false",
  }, { stdin = cfg, text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        cb(nil, "curl failed (" .. res.code .. "): " .. vim.trim(res.stderr or ""))
        return
      end
      local ok, data = pcall(vim.json.decode, res.stdout)
      if not ok or type(data) ~= "table" or not data.passages or not data.passages[1] then
        cb(nil, "bad ESV response")
        return
      end
      cb(data, nil)
    end)
  end)
end

-- ---------------------------------------------------------------------------
-- Formatting + insertion
-- ---------------------------------------------------------------------------

-- "[16] Therefore ... (ESV)" -> { {n=16, text="..."} }
local function parse_verses(passage)
  local text = passage:gsub("%s*%(ESV%)%s*", " "):gsub("%s+", " ")
  local verses = {}
  for n, t in text:gmatch("%[(%d+)%]%s*([^%[]+)") do
    table.insert(verses, { n = tonumber(n), text = vim.trim(t) })
  end
  if #verses == 0 then
    table.insert(verses, { n = nil, text = vim.trim(text) })
  end
  return verses
end

-- Journal scripture-block format (pype.dev notes): admonition title carries the
-- canonical ref; one verse per indented line; ESV notice as a final italic line.
local function format_lines(entry, expanded)
  local lines = {
    (expanded and "!!!" or "???") .. ' scripture "' .. (entry.canonical or "?") .. '"',
    "",
  }
  for i, v in ipairs(entry.verses) do
    lines[#lines + 1] = "    " .. (v.n or i) .. ". " .. v.text
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "    _" .. COPYRIGHT .. "_"
  lines[#lines + 1] = ""
  return lines
end

M._cache = {}

local function put_lines(lines, buf, row)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  -- if the cursor line is empty, replace it; otherwise insert below it
  local at = row -- 0-based index where the block starts
  local cur = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
  if cur and cur:match("^%s*$") then
    at = row - 1
    vim.api.nvim_buf_set_lines(buf, at, row, false, lines)
  else
    vim.api.nvim_buf_set_lines(buf, at, at, false, lines)
  end
  -- land the cursor on the blank line after the quote so repeat inserts stack
  if vim.api.nvim_get_current_buf() == buf then
    pcall(vim.api.nvim_win_set_cursor, 0, { at + #lines, 0 })
  end
end

--- Fetch `input` (a bible reference) and insert it below the cursor as a
--- scripture admonition block. `expanded` = true uses `!!!` (memory-verse
--- style per the journal), else collapsible `???`. Async (vim.system);
--- errors surface via vim.notify.
function M.insert(input, expanded)
  local parsed, err = M.parse(input)
  if not parsed then
    vim.notify("Bible: " .. err, vim.log.levels.WARN)
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local cached = M._cache[parsed.query]
  if cached then
    put_lines(format_lines(cached, expanded), buf, row)
    return
  end
  fetch(parsed.query, function(data, ferr)
    if not data then
      vim.notify("Bible: " .. ferr, vim.log.levels.ERROR)
      return
    end
    local entry = { verses = parse_verses(data.passages[1]), canonical = data.canonical }
    M._cache[parsed.query] = entry
    put_lines(format_lines(entry, expanded), buf, row)
  end)
end

--- Guided picker for bare :Bible / <leader>bi:
--- book -> chapter -> start verse -> optional end verse -> insert.
--- `expanded` selects !!! over ??? admonition. Cancelling aborts quietly.
function M.pick(expanded)
  local names = {}
  for _, b in ipairs(BOOKS) do
    table.insert(names, b.name)
  end
  vim.ui.select(names, { prompt = "Bible book" }, function(name)
    if not name then
      return
    end
    local book
    for _, b in ipairs(BOOKS) do
      if b.name == name then
        book = b
        break
      end
    end
    local chs = CHAPTERS[book.id]
    local chapters = {}
    for i = 1, #chs do
      chapters[i] = i
    end
    vim.ui.select(chapters, { prompt = name .. " chapter" }, function(ch)
      if not ch then
        return
      end
      local verses = {}
      for i = 1, chs[ch] do
        verses[i] = i
      end
      vim.ui.select(verses, { prompt = name .. " " .. ch .. " verse" }, function(v1)
        if not v1 then
          return
        end
        local ref = name .. " " .. ch .. ":" .. v1
        if v1 == chs[ch] then -- last verse: no range possible, skip end-verse prompt
          M.insert(ref, expanded)
          return
        end
        local ends = { "(single verse)" }
        for i = v1 + 1, chs[ch] do
          ends[#ends + 1] = i
        end
        vim.ui.select(ends, { prompt = "Through verse" }, function(e)
          if not e then
            return
          end
          if type(e) == "number" then
            ref = ref .. "-" .. e
          end
          M.insert(ref, expanded)
        end)
      end)
    end)
  end)
end

--- :Bible handler — bare args open the picker, otherwise insert the ref.
--- `bang` (:Bible!) selects the expanded !!! admonition in either path.
function M.insert_or_pick(args, bang)
  if not args or vim.trim(args) == "" then
    M.pick(bang)
  else
    M.insert(args, bang)
  end
end

--- :command-completion for :Bible — book names.
--- Candidates: canonical names, last word of multi-word names (so "2 Cor"
--- completes), and squashed numbered names ("2Corinthians").
function M.complete(arglead)
  local a = arglead:lower()
  local seen, out = {}, {}
  local function add(c)
    if (a == "" or c:lower():find(a, 1, true) == 1) and not seen[c] then
      seen[c] = true
      table.insert(out, c)
    end
  end
  for _, b in ipairs(BOOKS) do
    add(b.name)
    local last = b.name:match("(%S+)$")
    if last ~= b.name then
      add(last)
    end
    local squashed = b.name:gsub("%s+", "")
    if squashed ~= b.name then
      add(squashed)
    end
  end
  table.sort(out)
  return out
end

--- Full-reference completion: book -> "book N" chapters -> "book N:" verses ->
--- "book N:M-" range end. arglead is the whole final token (vim splits on
--- whitespace only), so numeric candidates keep the token's non-digit prefix.
function M.complete_ref(arglead, cmdline, cursorpos)
  local typed = cmdline:sub(1, cursorpos)
  local refpart = typed:gsub("^%s*%S+", "") -- strip the command name
  local trailing_ws = typed:match("%s$") ~= nil
  local al = build_aliases()
  local book_key, rest = split_ref(norm(refpart), al)

  -- still in book-typing stage: no book recognized, or the token under the
  -- cursor is itself the (partial) book word
  if not book_key or (rest == "" and not trailing_ws and arglead ~= "") then
    return M.complete(arglead)
  end
  if not book_key then
    return M.complete(arglead)
  end

  local book = al[book_key][1]
  local chs = CHAPTERS[book.id]
  if not chs then
    return {}
  end

  -- candidates share arglead's non-digit stem ("4:", "2cor4:", "4:16-", "")
  local stem = arglead:gsub("%d*$", "")
  local frag = arglead:sub(#stem + 1)
  local function numbers(lo, hi)
    local out = {}
    for n = lo, hi do
      local s = tostring(n)
      if s:find(frag, 1, true) == 1 then
        out[#out + 1] = stem .. s
      end
    end
    return out
  end

  if rest == "" then -- "John " -> chapters
    return numbers(1, #chs)
  end
  if rest:match("^%d+$") then -- "John 3" / "john3" -> chapters
    return numbers(1, #chs)
  end
  local ch, v = rest:match("^(%d+):(%d*)$") -- "John 3:" / "John 3:1" -> verses
  if ch then
    local n = tonumber(ch)
    return n and chs[n] and numbers(1, chs[n]) or {}
  end
  local c2, v2 = rest:match("^(%d+)%-(%d*)$") -- "John 3-" -> chapter range
  if c2 then
    return numbers(tonumber(c2) + 1, #chs)
  end
  local rc, rv = rest:match("^(%d+):(%d+)%-(%d*)$") -- "John 3:16-" -> range end
  if rc then
    local n = tonumber(rc)
    return n and chs[n] and numbers(tonumber(rv) + 1, chs[n]) or {}
  end
  return {}
end

return M
