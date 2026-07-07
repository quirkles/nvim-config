-- Org-mode for Neovim: capture, TODO/agenda, outlining.
-- This is a NEW plugin add (not a LazyVim extra override), so it's a full
-- spec, not a delta. Notes live in ~/orgfiles — change the paths below to
-- move them (e.g. an iCloud/Dropbox folder if you want backup/sync).
--
-- Treesitter note: orgmode ships and manages its OWN `org` grammar
-- (parser/org.so inside the plugin). Do NOT add "org" to nvim-treesitter's
-- ensure_installed — the two would fight over the parser.
return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      require("orgmode").setup({
        -- Where agenda scans for TODOs/deadlines, and the default capture file.
        org_agenda_files = "~/orgfiles/**/*",
        org_default_notes_file = "~/orgfiles/inbox.org",

        -- Task lifecycle. Left of "|" = not done, right = done.
        org_todo_keywords = { "TODO", "NEXT", "WAITING", "|", "DONE", "CANCELLED" },

        -- Display polish (pairs with org-bullets below):
        -- indent body text under its headline instead of hugging the margin,
        org_startup_indented = true,
        -- and hide the *bold* / /italic/ / =code= markup characters. Needs
        -- conceallevel set on org buffers (see the ftplugin autocmd below).
        org_hide_emphasis_markers = true,

        -- Capture templates: <leader>oc then the letter.
        org_capture_templates = {
          r = {
            description = "Retro / planning / review topic",
            template = "* %?\n  Added: %U",
            target = "~/orgfiles/inbox.org",
          },
          t = {
            description = "Todo / next action",
            template = "* TODO %?\n  %u",
            target = "~/orgfiles/todos.org",
          },
          m = {
            description = "Meeting note (files under today's date)",
            template = "* %?",
            target = "~/orgfiles/meetings.org",
            datetree = true,
          },
        },

        -- Menu display (capture picker, agenda menu, etc.).
        -- orgmode's built-in menu just echoes text and blocks on getchar(),
        -- which snacks' notifier renders as a "Messages" toast that vanishes
        -- after ~3s — so the menu looks like it "times out" (it doesn't; it's
        -- still waiting). Route it through vim.ui.select instead: snacks turns
        -- that into a real, persistent picker (fuzzy-search + arrows, no timeout).
        ui = {
          menu = {
            handler = function(data)
              local options = {}
              local options_by_label = {}
              for _, item in ipairs(data.items) do
                -- Only actionable options have `key`; skip "Quit" (use <Esc>).
                if item.key and item.label:lower() ~= "quit" then
                  table.insert(options, item.label)
                  options_by_label[item.label] = item
                end
              end

              vim.ui.select(options, { prompt = data.prompt }, function(choice)
                if not choice then
                  return
                end
                local option = options_by_label[choice]
                if option and option.action then
                  option.action()
                end
              end)
            end,
          },
        },
      })

      -- org_hide_emphasis_markers only actually hides the markers when the
      -- buffer conceals them. LazyVim leaves conceallevel at 0 globally, so
      -- opt org buffers in here. concealcursor="nc" keeps them hidden while
      -- you're in normal/command mode but reveals them on the line you edit.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "org",
        callback = function()
          vim.opt_local.conceallevel = 2
          vim.opt_local.concealcursor = "nc"
        end,
      })
    end,
  },

  -- Pretty headline bullets: replaces the raw *, **, *** stars with ● ○ ✸ ✿.
  -- Purely cosmetic; the underlying text is still stars on disk.
  {
    "nvim-orgmode/org-bullets.nvim",
    ft = { "org" },
    config = function()
      require("org-bullets").setup()
    end,
  },
}
