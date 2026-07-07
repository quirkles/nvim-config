-- nvim-ufo: modern folding with an inline fold indicator.
-- LazyVim's default foldtext ("") shows a folded line as plain text with no
-- visual marker, which makes closed folds easy to miss. ufo appends virtual
-- text like `  45 lines ` so folds are obvious on the line itself.
return {
  "kevinhwang91/nvim-ufo",
  dependencies = { "kevinhwang91/promise-async" },
  event = "VeryLazy",
  init = function()
    -- ufo requires a high foldlevel so nothing is auto-closed on open.
    -- (LazyVim already sets these; reasserted here so ufo is self-contained.)
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
  end,
  opts = {
    -- Use treesitter for fold ranges, falling back to indent. Avoids relying
    -- on each LSP advertising folding-range support.
    provider_selector = function(_, _, _)
      return { "treesitter", "indent" }
    end,
    -- Suffix each folded line with a dimmed line count, e.g. `  45 lines `.
    fold_virt_text_handler = function(virt_text, lnum, end_lnum, width, truncate)
      local suffix = ("  %d lines "):format(end_lnum - lnum)
      local sufWidth = vim.fn.strdisplaywidth(suffix)
      local target = width - sufWidth
      local cur = 0
      local result = {}
      for _, chunk in ipairs(virt_text) do
        local text = chunk[1]
        local w = vim.fn.strdisplaywidth(text)
        if target > cur + w then
          table.insert(result, chunk)
        else
          text = truncate(text, target - cur)
          table.insert(result, { text, chunk[2] })
          w = vim.fn.strdisplaywidth(text)
          if cur + w < target then
            suffix = suffix .. (" "):rep(target - cur - w)
          end
          break
        end
        cur = cur + w
      end
      table.insert(result, { suffix, "MoreMsg" })
      return result
    end,
  },
  keys = {
    -- zR / zM keep their meaning (open/close all) but go through ufo so its
    -- fold state stays consistent. za/zo/zc etc. are untouched by ufo.
    { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds (ufo)" },
    { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds (ufo)" },
    { "zr", function() require("ufo").openFoldsExceptKinds() end, desc = "Open folds except kinds (ufo)" },
    { "zm", function() require("ufo").closeFoldsWith() end, desc = "Close folds with (ufo)" },
    {
      "zK",
      function()
        local winid = require("ufo").peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end,
      desc = "Peek fold / hover (ufo)",
    },
  },
}
