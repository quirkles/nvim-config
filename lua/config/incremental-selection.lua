-- Syntax-aware selection, similar to IntelliJ's Expand/Shrink Selection.
-- nvim-treesitter's former incremental-selection module was removed in its
-- 1.0 rewrite, so this uses Neovim's native Tree-sitter node API directly.
local M = {}

local function before_or_equal(row_a, col_a, row_b, col_b)
  return row_a < row_b or (row_a == row_b and col_a <= col_b)
end

local function strictly_before(row_a, col_a, row_b, col_b)
  return row_a < row_b or (row_a == row_b and col_a < col_b)
end

local function node_range(node)
  local start_row, start_col, end_row, end_col = node:range()
  return { start_row = start_row, start_col = start_col, end_row = end_row, end_col = end_col }
end

local function contains(node, range)
  local node_range_ = node_range(node)
  return before_or_equal(node_range_.start_row, node_range_.start_col, range.start_row, range.start_col)
    and before_or_equal(range.end_row, range.end_col, node_range_.end_row, node_range_.end_col)
end

local function same_range(left, right)
  return left.start_row == right.start_row
    and left.start_col == right.start_col
    and left.end_row == right.end_row
    and left.end_col == right.end_col
end

local function visual_range()
  if not vim.fn.mode():find("^[vV\22]") then
    return nil
  end

  local anchor = vim.fn.getpos("v")
  local cursor = vim.fn.getpos(".")
  -- `getpos()` columns are 1-indexed; Tree-sitter/API columns are 0-indexed.
  local start_row, start_col = anchor[2] - 1, anchor[3] - 1
  local end_row, end_col = cursor[2] - 1, cursor[3] - 1

  if not before_or_equal(start_row, start_col, end_row, end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  -- Tree-sitter ranges are end-exclusive. Visual mode is normally inclusive,
  -- but honour users who have explicitly configured `:set selection=exclusive`.
  if vim.o.selection == "inclusive" then
    end_col = end_col + 1
  end
  return { start_row = start_row, start_col = start_col, end_row = end_row, end_col = end_col }
end

local function select(range)
  local end_row, end_col = range.end_row, range.end_col
  local line_count = vim.api.nvim_buf_line_count(0)

  -- Tree-sitter ranges are end-exclusive. A node that reaches EOF often ends
  -- at column 0 on the imaginary line after the buffer; that is not a valid
  -- cursor position, so select the final real character instead.
  if end_row >= line_count or (end_col == 0 and end_row > range.start_row) then
    end_row = math.min(end_row - 1, line_count - 1)
    end_col = #vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1]
  end

  vim.cmd("normal! " .. vim.keycode("<Esc>"))
  vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, { end_row + 1, math.max(end_col - 1, 0) })
  return { start_row = range.start_row, start_col = range.start_col, end_row = end_row, end_col = end_col }
end

local function named_node_at(row, col)
  -- A parser can be installed without being actively attached to the buffer.
  -- Parse on demand so scope navigation works in every supported filetype,
  -- not only after highlighting has happened to start Tree-sitter.
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if not ok then
    return nil
  end
  parser:parse()

  local node = vim.treesitter.get_node({ pos = { row, col } })
  while node and not node:named() do
    node = node:parent()
  end
  return node
end

local function final_character(range)
  if range.end_col > 0 then
    return range.end_row, range.end_col - 1
  end

  local row = range.end_row - 1
  if row < 0 then
    return nil
  end
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
  return row, math.max(#line - 1, 0)
end

-- These are meaningful lexical / structural tiers. Deliberately exclude small
-- expression fragments such as `member_expression`, which made [[ appear to do
-- nothing when the cursor was at the end of `object.property`.
local scope_node_types = {
  program = true,
  module = true,
  export_statement = true,
  lexical_declaration = true,
  variable_declarator = true,
  function_declaration = true,
  function_expression = true,
  arrow_function = true,
  method_definition = true,
  class_declaration = true,
  class_body = true,
  statement_block = true,
  if_statement = true,
  switch_statement = true,
  for_statement = true,
  while_statement = true,
  try_statement = true,
  arguments = true,
  formal_parameters = true,
  object = true,
  array = true,
  function_definition = true,
  compound_statement = true,
  subshell = true,
}

local function is_structural(node)
  return scope_node_types[node:type()]
end

-- Move between the starts and ends of enclosing syntax nodes. Repeating the
-- motion climbs outward, but nodes sharing the current boundary are skipped so
-- each press reaches a visibly different scope level.
function M.scope_start()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local node = named_node_at(row - 1, col)

  if not node then
    vim.notify("No Tree-sitter parser is available for this buffer", vim.log.levels.WARN)
    return
  end

  while node do
    local range = node_range(node)
    if is_structural(node) and strictly_before(range.start_row, range.start_col, row - 1, col) then
      vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
      return
    end
    node = node:parent()
  end
end

function M.scope_end()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local node = named_node_at(row - 1, col)

  if not node then
    vim.notify("No Tree-sitter parser is available for this buffer", vim.log.levels.WARN)
    return
  end

  while node do
    local range = node_range(node)
    local end_row, end_col = final_character(range)
    if end_row and is_structural(node) and strictly_before(row - 1, col, end_row, end_col) then
      vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
      return
    end
    node = node:parent()
  end
end

local function install_scope_mappings(buffer)
  if not vim.api.nvim_buf_is_valid(buffer) or vim.bo[buffer].buftype ~= "" then
    return
  end

  -- Buffer-local mappings take precedence over LazyVim/plugin global mappings.
  vim.keymap.set("n", "[[", M.scope_start, { buffer = buffer, desc = "Previous syntax scope start" })
  vim.keymap.set("n", "]]", M.scope_end, { buffer = buffer, desc = "Next syntax scope end" })
end

function M.expand()
  local selected_range = visual_range()
  local state = vim.b.incremental_selection_state
  local node

  -- Once selection has started, use the saved Tree-sitter node range rather
  -- than reconstructing it from Visual-mode cursor positions. This makes
  -- expanding and shrinking perfectly reversible.
  if selected_range and state and same_range(selected_range, state.visual_ranges[#state.visual_ranges]) then
    local current_range = state.node_ranges[#state.node_ranges]
    node = named_node_at(current_range.start_row, current_range.start_col)
    while node and not same_range(node_range(node), current_range) do
      node = node:parent()
    end
    node = node and node:parent() or nil
    while node and not node:named() do
      node = node:parent()
    end
  elseif selected_range then
    node = named_node_at(selected_range.start_row, selected_range.start_col)
    while node and not contains(node, selected_range) do
      node = node:parent()
    end
    if node and same_range(node_range(node), selected_range) then
      node = node:parent()
    end
    while node and not node:named() do
      node = node:parent()
    end
    state = { node_ranges = {}, visual_ranges = {} }
  else
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    node = named_node_at(row - 1, col)
    state = { node_ranges = {}, visual_ranges = {} }
  end

  if not node then
    vim.notify("No Tree-sitter syntax node at the cursor", vim.log.levels.WARN)
    return
  end

  local range = node_range(node)
  table.insert(state.node_ranges, range)
  table.insert(state.visual_ranges, select(range))
  vim.b.incremental_selection_state = state
end

function M.shrink()
  local state = vim.b.incremental_selection_state
  if state and #state.node_ranges > 1 then
    table.remove(state.node_ranges)
    table.remove(state.visual_ranges)
    select(state.node_ranges[#state.node_ranges])
    vim.b.incremental_selection_state = state
  else
    vim.b.incremental_selection_state = nil
    vim.cmd("normal! " .. vim.keycode("<Esc>"))
  end
end

function M.setup()
  vim.keymap.set({ "n", "x" }, "<M-Up>", M.expand, { desc = "Expand syntax selection" })
  vim.keymap.set({ "n", "x" }, "<M-Down>", M.shrink, { desc = "Shrink syntax selection" })

  local group = vim.api.nvim_create_augroup("incremental_selection_scope_mappings", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(event)
      install_scope_mappings(event.buf)
    end,
  })

  local function install_after_deferred_plugins()
    vim.schedule(function()
      for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        install_scope_mappings(buffer)
      end
    end)
  end

  -- LazyVim's Illuminate extra deliberately installs [[ and ]] after its
  -- plugin/config events. Reapply our buffer-local mappings afterwards.
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = install_after_deferred_plugins,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "LazyFile",
    callback = install_after_deferred_plugins,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = install_after_deferred_plugins,
  })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = install_after_deferred_plugins,
  })

  -- Keymaps are loaded on LazyVim's VeryLazy event, after the initial buffer
  -- may already have been entered.
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    install_scope_mappings(buffer)
  end
end

return M
