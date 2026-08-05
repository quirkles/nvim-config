-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- These must be available before LazyVim's deferred keymap setup runs.
require("config.incremental-selection").setup()

-- Rewrite renamed plugin owners in this config instead of being nagged about
-- them on every startup. Also available on demand as `:LazyFixRenames`.
require("config.fix-plugin-renames").setup()
