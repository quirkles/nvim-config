-- LazyVim detects plugins whose owner/repo has moved, silently rewrites the
-- spec in memory, and then warns on every startup asking you to update your
-- config by hand. It already knows the old and new names, so apply its own
-- rename map to the config files on disk and stop the nagging permanently.
local M = {}

local TITLE = "Plugin renames"

-- Rewriting this file would corrupt the rename examples in its own comments.
local SELF = debug.getinfo(1, "S").source:sub(2)

-- This runs during startup, before the notification UI is loaded, so defer the
-- message. The rewrite itself has already happened by the time it appears.
local function notify(message, level)
  vim.schedule(function()
    vim.notify(message, level, { title = TITLE })
  end)
end

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local contents = file:read("*a")
  file:close()
  return contents
end

local function write_file(path, contents)
  local file = io.open(path, "w")
  if not file then
    return false
  end
  file:write(contents)
  file:close()
  return true
end

-- Plain-text search and replace. Plugin names contain `.` and `-`, which are
-- Lua pattern metacharacters, so `gsub` would need escaping to be correct.
local function replace_all(subject, needle, replacement)
  local parts, index, count = {}, 1, 0
  while true do
    local from, to = subject:find(needle, index, true)
    if not from then
      break
    end
    table.insert(parts, subject:sub(index, from - 1))
    table.insert(parts, replacement)
    index = to + 1
    count = count + 1
  end
  table.insert(parts, subject:sub(index))
  return table.concat(parts, ""), count
end

-- Whole-owner moves, applied to any repo under them. LazyVim knows this one
-- too, but only adds a map entry for names it actually saw in a collected
-- spec, so it misses references it never evaluated: lazily-loaded
-- dependencies, specs behind a condition, commented-out lines.
local OWNER_RENAMES = {
  ["echasnovski/"] = "nvim-mini/",
}

local function apply_renames(contents, renames)
  local applied = {}

  for old, new in pairs(OWNER_RENAMES) do
    -- Anchored on the opening quote, so only a name's owner segment matches.
    for _, quote in ipairs({ '"', "'" }) do
      local count
      contents, count = replace_all(contents, quote .. old, quote .. new)
      if count > 0 then
        applied[old .. "*"] = new .. "*"
      end
    end
  end

  for old, new in pairs(renames) do
    -- Match whole quoted strings only. Some of LazyVim's entries are bare
    -- repo names rather than owner/repo, and a substring match would corrupt
    -- any name that merely contains a renamed one: the markdown.nvim entry
    -- would keep re-prefixing an already-correct render-markdown.nvim.
    for _, quote in ipairs({ '"', "'" }) do
      local count
      contents, count = replace_all(contents, quote .. old .. quote, quote .. new .. quote)
      if count > 0 then
        applied[old] = new
      end
    end
  end
  return contents, applied
end

local function config_files()
  local root = vim.fn.stdpath("config")
  local files, seen = {}, {}
  for _, pattern in ipairs({ "*.lua", "**/*.lua" }) do
    for _, path in ipairs(vim.fn.globpath(root, pattern, false, true)) do
      if not seen[path] and path ~= SELF then
        seen[path] = true
        table.insert(files, path)
      end
    end
  end
  return files
end

---@param opts? { notify_when_clean?: boolean }
function M.run(opts)
  opts = opts or {}

  local ok, lazyvim_plugin = pcall(require, "lazyvim.util.plugin")
  if not ok then
    notify("LazyVim's rename map is unavailable", vim.log.levels.WARN)
    return
  end

  -- LazyVim seeds this table with known moves and adds an entry for every
  -- `echasnovski/*` spec it encounters while collecting them, so by now it
  -- covers everything this config actually references.
  local renames = lazyvim_plugin.renames
  local changed = {}

  for _, path in ipairs(config_files()) do
    local contents = read_file(path)
    if contents then
      local updated, applied = apply_renames(contents, renames)
      if updated ~= contents and write_file(path, updated) then
        table.insert(changed, { path = path, applied = applied })
      end
    end
  end

  if #changed == 0 then
    if opts.notify_when_clean then
      notify("No renamed plugins in your config", vim.log.levels.INFO)
    end
    return
  end

  local lines = {}
  for _, entry in ipairs(changed) do
    for old, new in pairs(entry.applied) do
      table.insert(lines, ("%s: `%s` → `%s`"):format(vim.fn.fnamemodify(entry.path, ":~:."), old, new))
    end
  end
  table.insert(lines, "Restart Neovim to clear the rename warning.")
  notify(table.concat(lines, "\n"), vim.log.levels.INFO)

  -- Reload any rewritten file that is already open in a buffer.
  vim.cmd("checktime")
end

function M.setup()
  vim.api.nvim_create_user_command("LazyFixRenames", function()
    M.run({ notify_when_clean = true })
  end, { desc = "Rewrite renamed plugin names in this config" })

  -- Runs synchronously during startup rather than on `VeryLazy`, which is not
  -- guaranteed to fire (headless sessions quit before it does). `lazy.setup()`
  -- has already collected every spec by the time this is reached, so the
  -- rename map is complete and there is nothing to wait for.
  M.run()
end

return M
