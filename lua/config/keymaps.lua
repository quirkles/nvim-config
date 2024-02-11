local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>Tr", builtin.lsp_references, { desc = "LSP References" })
