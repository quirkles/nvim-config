-- Delta override for neo-tree: make `s` trigger flash inside the tree,
-- matching the global `s` flash motion so muscle memory is consistent.
-- (Default `s` was open_vsplit — dropped; <CR> opens files, `S` still splits.)
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    window = {
      mappings = {
        ["s"] = function()
          require("flash").jump()
        end,
        ["h"] = function(state)
          local parent_id = state.tree:get_node():get_parent_id()
          if parent_id then
            require("neo-tree.ui.renderer").focus_node(state, parent_id)
          end
        end,
        ["F"] = function(state)
          local node = state.tree:get_node()
          local path = node.path

          -- Search inside the selected directory, or beside a selected file.
          if node.type ~= "directory" then
            path = vim.fs.dirname(path)
          end

          require("fzf-lua").files({ cwd = path })
        end,
        ["G"] = function(state)
          local node = state.tree:get_node()
          local path = node.path

          -- Search file contents inside the selected directory, or beside a file.
          if node.type ~= "directory" then
            path = vim.fs.dirname(path)
          end

          require("fzf-lua").live_grep({ cwd = path })
        end,
      },
    },
  },
}
