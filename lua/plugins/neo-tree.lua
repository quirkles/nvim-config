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
      },
    },
  },
}
