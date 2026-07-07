-- Colorscheme switcher: auto-discovered themes + live preview + persistence.
--
-- Themes are git-cloned (not managed by lazy directly) into:
--   ~/.local/share/nvim/site/pack/themes/start/
-- by `scripts/install-colorschemes.sh`. This file scans that directory and
-- registers each cloned repo as a local lazy plugin, so lazy handles the
-- runtimepath/loading (lazy resets rtp, so Neovim's native package loading
-- won't pick them up on its own — that's why we do it here).
--
-- Usage:
--   * Browse/preview/switch live:  <leader>uC   (snacks colorscheme picker)
--   * Your pick is saved and restored on the next launch (below).
--   * Add more themes: add a repo to scripts/install-colorschemes.sh and re-run
--     it (or `git clone` any theme repo into the dir above), then restart nvim.

local themes_dir = vim.fn.stdpath("data") .. "/site/pack/themes/start"
local persist_file = vim.fn.stdpath("data") .. "/colorscheme.txt"
local fallback = "tokyonight"

local function save_colorscheme(name)
  if not name or name == "" then
    return
  end
  local f = io.open(persist_file, "w")
  if f then
    f:write(name)
    f:close()
  end
end

local function load_colorscheme()
  local f = io.open(persist_file, "r")
  if not f then
    return nil
  end
  local name = f:read("*l")
  f:close()
  if name and name ~= "" then
    return name
  end
end

-- Persist whatever colorscheme becomes active (including picks from the picker).
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("persist_colorscheme", { clear = true }),
  callback = function(ev)
    save_colorscheme(ev.match)
  end,
})

local specs = {}

-- Discover every cloned theme and register it as a local plugin. Loaded eagerly
-- (lazy = false) so all their variants show up in the colorscheme picker.
for _, dir in ipairs(vim.fn.globpath(themes_dir, "*", true, true)) do
  if vim.fn.isdirectory(dir) == 1 then
    specs[#specs + 1] = {
      dir = dir,
      name = vim.fn.fnamemodify(dir, ":t"),
      lazy = false,
      priority = 1000,
    }
  end
end

-- Restore the last-used colorscheme (function form so we can fall back safely).
specs[#specs + 1] = {
  "LazyVim/LazyVim",
  opts = {
    colorscheme = function()
      -- Dark-only setup: keep background dark so themes that key off it
      -- (gruvbox, everforest, melange, ...) don't render their light variant.
      vim.o.background = "dark"
      local name = load_colorscheme() or fallback
      if not pcall(vim.cmd.colorscheme, name) then
        pcall(vim.cmd.colorscheme, fallback)
      end
    end,
  },
}

return specs
