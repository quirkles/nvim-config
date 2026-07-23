-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- These must be available before LazyVim's deferred keymap setup runs.
require("config.incremental-selection").setup()
