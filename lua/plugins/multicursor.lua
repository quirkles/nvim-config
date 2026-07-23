-- Multi-cursor editing — the IntelliJ / VSCode "Cmd+D" muscle memory.
-- Not a LazyVim extra, so this is a full spec.
--
-- Core motions (all in normal mode, on a word or visual selection):
--   <C-n>        select word under cursor; press again to add the NEXT match
--                (exactly like IntelliJ Alt+J / VSCode Cmd+D)
--   <C-Down>/<C-Up>  add a cursor DOWN / UP a line (vertical column of cursors)
--                    NOTE: macOS grabs Ctrl+Up/Down for Mission Control — see
--                    the add-cursor binding decision below / in keymaps.lua.
--   n / N        while in multi-cursor mode: go to next/prev match
--   q            skip the current match, jump to the next
--   [ / ]        cycle between active cursors
--   <Esc>        leave multi-cursor mode
-- Then just type — normal Vim operators (c, d, i, a, ~, etc.) apply to every cursor.
return {
  "mg979/vim-visual-multi",
  branch = "master",
  -- Load early (not key-lazy) so the <Plug> maps exist before keymaps.lua
  -- wires <C-j>/<C-k> to them, and so VM's own mappings are set deterministically.
  event = "VeryLazy",
  init = function()
    -- Leader key for the extended VM command set (e.g. \\A = select all matches).
    vim.g.VM_leader = "\\"
    -- Don't clobber the default theme; let the active colorscheme style it.
    vim.g.VM_set_statusline = 0
  end,
}
