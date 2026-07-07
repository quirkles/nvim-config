return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scratch = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    picker = {
      enabled = true,
      sources = {
        -- Dark-only colorscheme picker: reuse the built-in finder, then drop
        -- any light schemes/variants by name (bamboo-light, catppuccin-latte,
        -- github_light*, *-dawn, *-day, and light builtins).
        colorschemes = {
          finder = function(opts, ctx)
            local items = require("snacks.picker.source.vim").colorschemes(opts, ctx)
            local light = { "light", "latte", "dawn", "day", "morning", "shine", "peachpuff" }
            return vim.tbl_filter(function(item)
              local name = item.text:lower()
              for _, pat in ipairs(light) do
                if name:find(pat, 1, true) then
                  return false
                end
              end
              return true
            end, items)
          end,
        },
      },
    },
  },
  keys = {
    {
      "<leader>.",
      function()
        Snacks.scratch()
      end,
      desc = "Toggle Scratch Buffer",
    },
    {
      "<leader>S",
      function()
        Snacks.scratch.select()
      end,
      desc = "Select Scratch Buffer",
    },
  },
}
