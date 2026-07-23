-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Quick "open directory in Neotree" via aliases (see lua/config/dirs.lua)
require("config.dirs").setup()

-- Multicursor: add a cursor above/below on Ctrl+Up / Ctrl+Down.
-- LazyVim binds these to "resize window height" by default; we override that
-- here so they drive vim-visual-multi instead (its own default too, but our
-- override is what beats LazyVim's resize map). vim-visual-multi loads on
-- VeryLazy, so the <Plug> targets exist by the time these fire.
-- Window height resize is still available the long way: <C-w>+ and <C-w>-.
-- (Width resize on <C-Left>/<C-Right> and split nav on <C-h/j/k/l> are untouched.)
vim.keymap.set("n", "<C-Down>", "<Plug>(VM-Add-Cursor-Down)", { desc = "Add cursor below (multicursor)" })
vim.keymap.set("n", "<C-Up>", "<Plug>(VM-Add-Cursor-Up)", { desc = "Add cursor above (multicursor)" })
