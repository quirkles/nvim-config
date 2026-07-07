-- Quick directory aliases for opening Neotree at common locations.
-- Edit the two tables below — everything wires itself up in setup().
--
-- Dependencies:
--   neo-tree.nvim (HARD) — ships with LazyVim. Opens via the `:Neotree`
--     command, which lazy-loads the plugin on first use. Without it the
--     keymaps error (E492: Not an editor command) when pressed.
--   snacks.nvim (SOFT) — its picker overrides vim.ui.select to make the
--     <leader>fd list fuzzy-searchable. Without snacks it degrades to
--     Neovim's built-in select prompt (works, just plainer).
local M = {}

-- Destinations. Keys are the labels shown in the <leader>fd picker.
M.aliases = {
  ["nvim config"] = vim.fn.stdpath("config"), -- ~/.config/nvim
  ["monorepo"] = "~/code/part3-monorepo-poc",
  ["part3"] = "~/code/part3",
  ["dotfiles"] = "~/.config",
  ["orgfiles"] = "~/orgfiles",
  ["home"] = "~",
}

-- Direct one-key shortcuts: keymap suffix -> alias name (must exist above).
-- These are bound under <leader>f, e.g. "D" => <leader>fD.
M.shortcuts = {
  ["D"] = "monorepo",
  ["v"] = "nvim config",
  ["o"] = "orgfiles",
}

-- Open Neotree (filesystem source) rooted at the given path.
function M.open(path)
  local dir = vim.fn.expand(path)
  if vim.fn.isdirectory(dir) == 0 then
    vim.notify("Not a directory: " .. dir, vim.log.levels.WARN)
    return
  end
  -- `dir=` sets the tree root; action=focus opens and jumps to the tree
  vim.cmd("Neotree filesystem reveal=false action=focus dir=" .. vim.fn.fnameescape(dir))
end

-- Prompt with a picker over the aliases, then open the chosen one.
function M.pick()
  local names = vim.tbl_keys(M.aliases)
  table.sort(names)
  vim.ui.select(names, { prompt = "Open directory in Neotree" }, function(choice)
    if choice then
      M.open(M.aliases[choice])
    end
  end)
end

-- Register all keymaps. Called once from lua/config/keymaps.lua.
function M.setup()
  -- <leader>fd -> picker over all aliases
  vim.keymap.set("n", "<leader>fd", M.pick, { desc = "Open dir in Neotree (pick)" })

  -- Direct shortcuts from M.shortcuts
  for key, alias in pairs(M.shortcuts) do
    local path = M.aliases[alias]
    if path then
      vim.keymap.set("n", "<leader>f" .. key, function()
        M.open(path)
      end, { desc = "Open " .. alias .. " in Neotree" })
    else
      vim.notify("dirs.lua: unknown alias '" .. alias .. "' for <leader>f" .. key, vim.log.levels.WARN)
    end
  end
end

return M
