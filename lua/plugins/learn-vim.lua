-- Optional "learn better Vim habits" helpers, configured to stay OUT of the way.
-- Both are easy to toggle off; see the keymaps / commands noted below.
return {
  -- hardtime.nvim: nudges you toward efficient motions instead of spamming
  -- hjkl / reaching for arrows. Tuned to be gentle:
  --   * restriction_mode = "hint" -> it HINTS a better key, never BLOCKS you
  --   * mouse stays enabled (you came from IntelliJ)
  --   * a few repeats allowed before it says anything
  -- Toggle any time with :Hardtime toggle  (or :Hardtime disable to stop it).
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    event = "VeryLazy",
    opts = {
      restriction_mode = "hint",
      disable_mouse = false,
      hint = true,
      max_count = 4,
    },
  },

  -- precognition.nvim: shows virtual-text hints of which motion jumps where
  -- (e.g. a little "3w" / "b" near targets). Starts HIDDEN so it's never in
  -- your face — flip it on only when you're in "learning mode".
  --   Toggle: <leader>uP  (or :Precognition toggle)
  -- (<leader>up is taken by LazyVim's "toggle auto-pairs", so we use capital P.)
  {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    opts = {
      startVisible = false,
    },
    keys = {
      {
        "<leader>uP",
        function()
          require("precognition").toggle()
        end,
        desc = "Toggle Precognition hints",
      },
    },
  },
}
